import ActivityKit
import Combine
import CoreLocation
import Foundation
import SwiftUI
@preconcurrency import UserNotifications

// MARK: - Sesi

struct ChargeSession: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var startedAt: Date
    var endedAt: Date?
    var place: Place
    var unit: ChargerUnit
    var vehicle: Vehicle
    var startSoC: Double
    var targetSoC: Double
    var plan: Charge.Plan {
        .init(capacityKWh: vehicle.batteryKWh,
              startSoC: startSoC, targetSoC: targetSoC,
              ratedKW: vehicle.effectiveKW(on: unit),
              taperFloor: unit.taperFloor,
              ratePerKwh: unit.ratePerKwh,
              serviceFee: unit.serviceFee,
              speed: Charge.demoSpeed)
    }

    func elapsed(at now: Date = Date()) -> TimeInterval {
        (endedAt ?? now).timeIntervalSince(startedAt)
    }

    func soc(at now: Date = Date()) -> Double { Charge.soc(plan, after: elapsed(at: now)) }
    func energy(at now: Date = Date()) -> Double { Charge.energy(plan, at: soc(at: now)) }
    func cost(at now: Date = Date()) -> Int { Charge.cost(plan, at: soc(at: now)) }
    func addedKm(at now: Date = Date()) -> Int {
        Int((energy(at: now) * vehicle.kmPerKwh).rounded())
    }

    /// Kapan target tercapai. Nil kalau tidak akan tercapai.
    var finishAt: Date? {
        Charge.time(plan, toReach: targetSoC).map { startedAt.addingTimeInterval($0) }
    }
}

/// Kotak yang sudah dipindai tapi belum disetujui pemiliknya.
struct PendingCharge: Identifiable, Hashable {
    var place: Place
    var unit: ChargerUnit
    var id: String { place.id + "/" + unit.id }
}

// MARK: - Posisi

/// Dipakai cuma untuk mengurutkan SPKLU terdekat. Kalau izinnya ditolak,
/// titik acuannya jatuh ke pusat Jakarta dan aplikasinya tetap jalan.
@MainActor
final class Locator: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var lat: Double = Zetrum.defaultLat
    @Published private(set) var lon: Double = Zetrum.defaultLon
    @Published private(set) var live = false

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func ask() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let c = locs.last?.coordinate else { return }
        Task { @MainActor in
            lat = c.latitude; lon = c.longitude; live = true
        }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didFailWithError error: any Error) {}
}

// MARK: - Toko keadaan

@MainActor
final class ChargeStore: ObservableObject {

    @Published private(set) var active: ChargeSession?
    @Published private(set) var history: [ChargeSession] = []
    /// Dipublish tiap detik supaya tampilan ikut bergerak.
    @Published private(set) var now: Date = Date()
    /// Hasil pindaian yang masih menunggu persetujuan.
    @Published var pending: PendingCharge?

    @Published var vehicleID: String = Catalog.fallback.id { didSet { persistPrefs() } }
    @Published var nickname: String = ""                   { didSet { persistPrefs() } }
    @Published var startSoC: Double = 28                   { didSet { persistPrefs() } }
    @Published var targetSoC: Double = 90                  { didSet { persistPrefs() } }
    @Published var tileStyle: TileStyle = .dark            { didSet { persistPrefs() } }

    /// Bahasa antarmuka. Menyetel `Loc.lang` adalah yang membuat seluruh
    /// teks berganti; sesi yang sedang berjalan langsung didorong ulang
    /// supaya kartu di layar kunci ikut berganti tanpa menunggu detak.
    @Published var lang: Lang = .indonesian {
        didSet {
            guard oldValue != lang else { return }
            Loc.lang = lang
            persistPrefs()
            if let s = active { pushActivity(s, soc: s.soc(at: now)) }
        }
    }

    let locator = Locator()

    var vehicle: Vehicle { Catalog.vehicle(vehicleID) ?? Catalog.fallback }
    var vehicleLabel: String { nickname.isEmpty ? vehicle.displayName : nickname }

    private var timer: AnyCancellable?
    private var activity: Activity<ZetrumAttributes>?
    private var lastPushedSoC: Double = -1
    private var lastPushedAt: Date = .distantPast
    private var announcedFull = false

    private let activeKey = "state.active"
    private let historyKey = "state.history"
    private let fullNotificationID = "zetrum.full"

    init() {
        loadPrefs()
        load()
        reattachActivity()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in self?.tick(date) }
    }

    // MARK: Daftar SPKLU, sudah diurutkan dari yang terdekat

    func nearby(kind: VehicleKind? = nil, onlyAvailable: Bool = false,
                connector: Connector? = nil, search: String = "") -> [Place] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        return Zetrum.places
            .filter { p in
                if onlyAvailable && p.available == 0 { return false }
                if let c = connector, !p.units.contains(where: { $0.connector == c }) { return false }
                if !q.isEmpty {
                    let hay = (p.name + " " + p.address + " " + p.city + " " + p.venue.label).lowercased()
                    if !hay.contains(q) { return false }
                }
                return true
            }
            .sorted { distance(to: $0) < distance(to: $1) }
    }

    func distance(to p: Place) -> Double { p.distance(from: locator.lat, locator.lon) }

    // MARK: Rencana yang sedang disusun

    func plan(for unit: ChargerUnit) -> Charge.Plan {
        .init(capacityKWh: vehicle.batteryKWh, startSoC: startSoC, targetSoC: targetSoC,
              ratedKW: vehicle.effectiveKW(on: unit), taperFloor: unit.taperFloor,
              ratePerKwh: unit.ratePerKwh, serviceFee: unit.serviceFee,
              speed: Charge.demoSpeed)
    }

    func estimate(for unit: ChargerUnit) -> (duration: TimeInterval?, energy: Double, cost: Int, km: Int) {
        let p = plan(for: unit)
        let e = Charge.energy(p, at: targetSoC)
        return (Charge.time(p, toReach: targetSoC), e, Charge.cost(p, at: targetSoC),
                Int((e * vehicle.kmPerKwh).rounded()))
    }

    // MARK: Keadaan sesi berjalan

    var soc: Double { active?.soc(at: now) ?? startSoC }
    var energy: Double { active?.energy(at: now) ?? 0 }
    var cost: Int { active?.cost(at: now) ?? 0 }
    var addedKm: Int { active?.addedKm(at: now) ?? 0 }
    var power: Double { active.map { Charge.power($0.plan, at: soc) } ?? 0 }
    var isFull: Bool { active.map { Charge.isDone($0.plan, at: soc) } ?? false }
    var finishAt: Date? { active?.finishAt }

    var remaining: TimeInterval? {
        guard let f = finishAt, !isFull else { return nil }
        return max(0, f.timeIntervalSince(now))
    }

    var spentThisMonth: Int {
        let cal = Calendar.current
        return history
            .filter { cal.isDate($0.endedAt ?? $0.startedAt, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.cost() }
    }

    var energyThisMonth: Double {
        let cal = Calendar.current
        return history
            .filter { cal.isDate($0.endedAt ?? $0.startedAt, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.energy() }
    }

    var sessionsThisMonth: Int {
        let cal = Calendar.current
        return history.filter {
            cal.isDate($0.endedAt ?? $0.startedAt, equalTo: Date(), toGranularity: .month)
        }.count
    }

    /// Kira-kira berapa kilogram CO₂ yang tidak keluar dibanding mobil bensin.
    /// 1 kWh listrik PLN ≈ 0,85 kg CO₂; mobil bensin ≈ 0,19 kg CO₂ per km.
    var co2SavedKg: Double {
        let km = energyThisMonth * vehicle.kmPerKwh
        let petrol = km * (vehicle.kind == .car ? 0.192 : 0.062)   // kg CO2 per km
        let grid = energyThisMonth * 0.85                          // kg CO2 per kWh PLN
        return max(0, petrol - grid)
    }

    // MARK: Aksi

    /// Hasil pindaian; belum mengisi apa-apa sampai pemiliknya menyetujui.
    @discardableResult
    func scanned(code: String) -> Bool {
        guard let (p, u) = Zetrum.lookup(code: code) else { return false }
        pending = PendingCharge(place: p, unit: u)
        Haptic.tick()
        return true
    }

    func offer(_ place: Place, _ unit: ChargerUnit) {
        pending = PendingCharge(place: place, unit: unit)
    }

    /// Dipanggil hanya setelah pemiliknya menekan tombol setuju.
    func confirmPending() {
        guard let p = pending else { return }
        pending = nil
        start(at: p.place, unit: p.unit)
    }

    func start(at place: Place, unit: ChargerUnit) {
        guard active == nil, targetSoC > startSoC, vehicle.accepts(unit) else { return }
        let session = ChargeSession(
            startedAt: Date(), place: place, unit: unit, vehicle: vehicle,
            startSoC: startSoC, targetSoC: targetSoC)
        active = session
        now = Date()
        announcedFull = false
        save()
        Haptic.thud()
        beginActivity(for: session)
        scheduleFullNotification(for: session)
    }

    @discardableResult
    func stop() -> ChargeSession? {
        guard var session = active else { return nil }
        session.endedAt = Date()
        active = nil
        history.insert(session, at: 0)
        if history.count > 80 { history.removeLast(history.count - 80) }
        // lanjutkan dari persen terakhir, seperti mobil sungguhan
        startSoC = min(99, session.soc(at: session.endedAt!))
        save()
        Haptic.ok()
        cancelFullNotification()
        endActivity(final: session)
        return session
    }

    func clearHistory() {
        history.removeAll()
        save()
    }

    // MARK: Detak

    private func tick(_ date: Date) {
        now = date
        guard let session = active else { return }
        let s = session.soc(at: date)

        if !announcedFull && Charge.isDone(session.plan, at: s) {
            announcedFull = true
            Haptic.ok()
            pushActivity(session, soc: s)
            return
        }
        // dorong kabar baru tiap seperempat persen, atau paling lambat semenit
        if abs(s - lastPushedSoC) >= 0.25 || date.timeIntervalSince(lastPushedAt) > 60 {
            pushActivity(session, soc: s)
        }
    }

    // MARK: Live Activity

    private func contentState(_ session: ChargeSession, soc s: Double) -> ZetrumAttributes.ContentState {
        .init(plan: session.plan,
              startedAt: session.startedAt,
              soc: s,
              energy: Charge.energy(session.plan, at: s),
              cost: Charge.cost(session.plan, at: s),
              power: Charge.power(session.plan, at: s),
              finishAt: session.finishAt,
              isDone: Charge.isDone(session.plan, at: s),
              lang: lang.rawValue)
    }

    private func attributes(_ session: ChargeSession) -> ZetrumAttributes {
        .init(stationName: session.place.name,
              stationArea: session.place.city,
              connector: session.unit.connector.label,
              powerLabel: Daya.kw(session.vehicle.effectiveKW(on: session.unit)) + " kW",
              carName: nickname.isEmpty ? session.vehicle.displayName : nickname,
              isBike: session.vehicle.kind == .bike)
    }

    private func beginActivity(for session: ChargeSession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let state = contentState(session, soc: session.startSoC)
        do {
            activity = try Activity.request(
                attributes: attributes(session),
                content: .init(state: state, staleDate: Date().addingTimeInterval(180)),
                pushType: nil
            )
            lastPushedSoC = state.soc
            lastPushedAt = Date()
        } catch {
            activity = nil
        }
    }

    private func pushActivity(_ session: ChargeSession, soc s: Double) {
        lastPushedSoC = s
        lastPushedAt = Date()
        guard let activity else { return }
        let state = contentState(session, soc: s)
        Task {
            await activity.update(.init(state: state,
                                        staleDate: Date().addingTimeInterval(180)))
        }
    }

    private func endActivity(final session: ChargeSession) {
        guard let activity else { return }
        let state = contentState(session, soc: session.soc(at: session.endedAt ?? Date()))
        self.activity = nil
        lastPushedSoC = -1
        Task {
            await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .immediate)
        }
    }

    /// Dipanggil saat app dibuka lagi. Tiga kemungkinan: sesi masih ada dan
    /// kartunya hidup (sambungkan), sesi ada tapi kartunya hilang (buat ulang),
    /// atau tidak ada sesi tapi kartunya nyangkut (tutup).
    private func reattachActivity() {
        activity = Activity<ZetrumAttributes>.activities.first

        if let session = active {
            announcedFull = Charge.isDone(session.plan, at: session.soc(at: Date()))
            if let live = activity {
                lastPushedSoC = live.content.state.soc
                lastPushedAt = Date()
            } else {
                beginActivity(for: session)
            }
        } else if let stale = activity {
            Task { await stale.end(nil, dismissalPolicy: .immediate) }
            activity = nil
        }
    }

    // MARK: Kabar saat penuh

    /// Kendaraannya ditinggal, jadi kabar "sudah penuh" dikirim walau
    /// aplikasi sedang tidak dibuka. Dijadwalkan sekali di depan karena
    /// waktu selesainya sudah diketahui.
    private func scheduleFullNotification(for session: ChargeSession) {
        guard let finish = session.finishAt else { return }
        let wait = finish.timeIntervalSinceNow
        guard wait > 5 else { return }

        let name = nickname.isEmpty ? session.vehicle.displayName : nickname
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = T("notify.title")
            content.body = T("notify.body", name, Energi.persen(session.targetSoC),
                             session.place.name, Rupiah.full(session.cost(at: finish)))
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: wait, repeats: false)
            center.add(.init(identifier: "zetrum.full", content: content, trigger: trigger))
        }
    }

    private func cancelFullNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [fullNotificationID])
    }

    // MARK: Simpan

    private func save() {
        let enc = JSONEncoder()
        let d = UserDefaults.standard
        d.set(try? enc.encode(active), forKey: activeKey)
        d.set(try? enc.encode(history), forKey: historyKey)
    }

    private func load() {
        let dec = JSONDecoder()
        let d = UserDefaults.standard
        if let raw = d.data(forKey: activeKey) {
            active = try? dec.decode(ChargeSession?.self, from: raw)
        }
        if let raw = d.data(forKey: historyKey) {
            history = (try? dec.decode([ChargeSession].self, from: raw)) ?? []
        }
    }

    private func persistPrefs() {
        let d = UserDefaults.standard
        d.set(vehicleID, forKey: "pref.vehicle")
        d.set(nickname, forKey: "pref.nickname")
        d.set(startSoC, forKey: "pref.startSoC")
        d.set(targetSoC, forKey: "pref.targetSoC")
        d.set(tileStyle.rawValue, forKey: "pref.tiles")
        d.set(lang.rawValue, forKey: "pref.lang")
    }

    private func loadPrefs() {
        let d = UserDefaults.standard
        // bahasanya dulu, supaya nilai lain yang ikut diformat sudah benar
        lang = Lang(rawValue: d.string(forKey: "pref.lang") ?? "") ?? .indonesian
        Loc.lang = lang
        vehicleID = d.string(forKey: "pref.vehicle") ?? Catalog.fallback.id
        nickname = d.string(forKey: "pref.nickname") ?? ""
        if d.object(forKey: "pref.startSoC") != nil { startSoC = d.double(forKey: "pref.startSoC") }
        if d.object(forKey: "pref.targetSoC") != nil { targetSoC = d.double(forKey: "pref.targetSoC") }
        tileStyle = TileStyle(rawValue: d.string(forKey: "pref.tiles") ?? "") ?? .dark
    }
}
