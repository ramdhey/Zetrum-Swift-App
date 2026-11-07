import ActivityKit
import Combine
import Foundation
import SwiftUI
import UserNotifications

struct ChargeSession: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var startedAt: Date
    var endedAt: Date?
    var station: Station
    var carName: String
    var capacityKWh: Double
    var startSoC: Double
    var targetSoC: Double

    var plan: Charge.Plan {
        .init(capacityKWh: capacityKWh, startSoC: startSoC, targetSoC: targetSoC,
              ratedKW: station.ratedKW, taperFloor: station.connector.taperFloor,
              ratePerKwh: station.ratePerKwh)
    }

    func elapsed(at now: Date = Date()) -> TimeInterval {
        (endedAt ?? now).timeIntervalSince(startedAt)
    }

    func soc(at now: Date = Date()) -> Double { Charge.soc(plan, after: elapsed(at: now)) }
    func energy(at now: Date = Date()) -> Double { Charge.energy(plan, at: soc(at: now)) }
    func cost(at now: Date = Date()) -> Int { Charge.cost(plan, at: soc(at: now)) }

    /// Kapan target tercapai. Nil kalau tidak akan tercapai.
    var finishAt: Date? {
        Charge.time(plan, toReach: targetSoC).map { startedAt.addingTimeInterval($0) }
    }
}

@MainActor
final class ChargeStore: ObservableObject {

    @Published private(set) var active: ChargeSession?
    @Published private(set) var history: [ChargeSession] = []
    /// Dipublish tiap detik supaya tampilan ikut bergerak.
    @Published private(set) var now: Date = Date()

    // Mobilnya satu, punya sendiri — jadi cukup disimpan sebagai preferensi.
    @Published var carName: String = "Mobil saya"        { didSet { persistPrefs() } }
    @Published var capacityKWh: Double = 64              { didSet { persistPrefs() } }
    @Published var startSoC: Double = 28                 { didSet { persistPrefs() } }
    @Published var targetSoC: Double = 90                { didSet { persistPrefs() } }
    @Published var stationID: String = Station.fallback.id { didSet { persistPrefs() } }

    var station: Station {
        Station.all.first { $0.id == stationID } ?? Station.fallback
    }

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

    // MARK: - Rencana yang sedang disusun (sebelum mulai)

    var draftPlan: Charge.Plan {
        .init(capacityKWh: capacityKWh, startSoC: startSoC, targetSoC: targetSoC,
              ratedKW: station.ratedKW, taperFloor: station.connector.taperFloor,
              ratePerKwh: station.ratePerKwh)
    }

    var draftDuration: TimeInterval? { Charge.time(draftPlan, toReach: targetSoC) }
    var draftEnergy: Double { Charge.energy(draftPlan, at: targetSoC) }
    var draftCost: Int { Charge.cost(draftPlan, at: targetSoC) }

    // MARK: - Keadaan sesi berjalan

    var soc: Double { active?.soc(at: now) ?? startSoC }
    var energy: Double { active?.energy(at: now) ?? 0 }
    var cost: Int { active?.cost(at: now) ?? 0 }
    var power: Double { active.map { Charge.power($0.plan, at: soc) } ?? 0 }
    var isFull: Bool { active.map { Charge.isDone($0.plan, at: soc) } ?? false }
    var finishAt: Date? { active?.finishAt }

    var remaining: TimeInterval? {
        guard let f = finishAt, !isFull else { return nil }
        return max(0, f.timeIntervalSince(now))
    }

    var spentToday: Int {
        let cal = Calendar.current
        return history
            .filter { cal.isDateInToday($0.endedAt ?? $0.startedAt) }
            .reduce(0) { $0 + $1.cost() }
    }

    // MARK: - Aksi

    func start() {
        guard active == nil, targetSoC > startSoC else { return }
        let session = ChargeSession(
            startedAt: Date(), station: station,
            carName: carName.trimmingCharacters(in: .whitespaces),
            capacityKWh: capacityKWh, startSoC: startSoC, targetSoC: targetSoC
        )
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
        if history.count > 60 { history.removeLast(history.count - 60) }
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

    // MARK: - Detak

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

    // MARK: - Live Activity

    private func contentState(_ session: ChargeSession, soc s: Double) -> ZetrumAttributes.ContentState {
        .init(plan: session.plan,
              startedAt: session.startedAt,
              soc: s,
              energy: Charge.energy(session.plan, at: s),
              cost: Charge.cost(session.plan, at: s),
              power: Charge.power(session.plan, at: s),
              finishAt: session.finishAt,
              isDone: Charge.isDone(session.plan, at: s))
    }

    private func attributes(_ session: ChargeSession) -> ZetrumAttributes {
        .init(stationName: session.station.name,
              stationArea: session.station.area,
              connector: session.station.connector.label,
              powerLabel: session.station.powerLabel,
              carName: session.carName.isEmpty ? "Mobil saya" : session.carName)
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

    // MARK: - Kabar saat penuh

    /// Mobilnya ditinggal, jadi kabar "sudah penuh" dikirim walau aplikasi
    /// sedang tidak dibuka. Dijadwalkan sekali di depan karena waktu
    /// selesainya sudah diketahui.
    private func scheduleFullNotification(for session: ChargeSession) {
        guard let finish = session.finishAt else { return }
        let wait = finish.timeIntervalSinceNow
        guard wait > 5 else { return }

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let body = "\(session.carName) sudah \(Energi.persen(session.targetSoC))% di \(session.station.name). Total \(Rupiah.full(session.cost(at: finish)))."
            let content = UNMutableNotificationContent()
            content.title = "Pengisian selesai"
            content.body = body
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: wait, repeats: false)
            center.add(.init(identifier: "zetrum.full", content: content, trigger: trigger))
        }
    }

    private func cancelFullNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [fullNotificationID])
    }

    // MARK: - Simpan

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
        d.set(carName, forKey: "pref.car")
        d.set(capacityKWh, forKey: "pref.capacity")
        d.set(startSoC, forKey: "pref.startSoC")
        d.set(targetSoC, forKey: "pref.targetSoC")
        d.set(stationID, forKey: "pref.station")
    }

    private func loadPrefs() {
        let d = UserDefaults.standard
        carName = d.string(forKey: "pref.car") ?? "Mobil saya"
        if d.object(forKey: "pref.capacity") != nil { capacityKWh = d.double(forKey: "pref.capacity") }
        if d.object(forKey: "pref.startSoC") != nil { startSoC = d.double(forKey: "pref.startSoC") }
        if d.object(forKey: "pref.targetSoC") != nil { targetSoC = d.double(forKey: "pref.targetSoC") }
        stationID = d.string(forKey: "pref.station") ?? Station.fallback.id
    }
}
