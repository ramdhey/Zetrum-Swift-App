import ActivityKit
import Combine
import Foundation
import SwiftUI

struct ParkingTicket: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var startedAt: Date
    var endedAt: Date?
    var ratePerHour: Int
    var mode: BillingMode
    var location: String
    var plate: String

    var duration: TimeInterval { (endedAt ?? Date()).timeIntervalSince(startedAt) }

    func cost(at now: Date = Date()) -> Int {
        Billing.cost(elapsed: (endedAt ?? now).timeIntervalSince(startedAt),
                     ratePerHour: ratePerHour, mode: mode)
    }
}

@MainActor
final class ParkingStore: ObservableObject {

    @Published private(set) var active: ParkingTicket?
    @Published private(set) var history: [ParkingTicket] = []
    /// Dipublish tiap detik supaya tampilan ikut berdetak.
    @Published private(set) var now: Date = Date()

    // Preferensi terakhir, supaya besok tidak ngetik ulang.
    // Sengaja @Published (bukan @AppStorage) agar perubahannya ikut menggerakkan tampilan.
    @Published var ratePerHour: Int = 3_000 { didSet { persistPrefs() } }
    @Published var mode: BillingMode = .hourly { didSet { persistPrefs() } }
    @Published var location: String = "" { didSet { persistPrefs() } }
    @Published var plate: String = "" { didSet { persistPrefs() } }

    private var timer: AnyCancellable?
    private var activity: Activity<ParkirAttributes>?
    private var lastPushedCost: Int = -1
    private var lastPushedAt: Date = .distantPast

    private let activeKey = "state.active"
    private let historyKey = "state.history"

    init() {
        loadPrefs()
        load()
        reattachActivity()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in self?.tick(date) }
    }

    // MARK: - Turunan untuk tampilan

    var elapsed: TimeInterval { active.map { now.timeIntervalSince($0.startedAt) } ?? 0 }

    var currentCost: Int {
        guard let a = active else { return 0 }
        return Billing.cost(elapsed: elapsed, ratePerHour: a.ratePerHour, mode: a.mode)
    }

    var nextTick: (at: Date, cost: Int)? {
        guard let a = active else { return nil }
        return Billing.nextTick(start: a.startedAt, now: now, ratePerHour: a.ratePerHour, mode: a.mode)
    }

    /// 0–1 menuju lompatan harga berikutnya.
    var tickProgress: Double {
        guard let a = active, a.mode == .hourly else {
            return elapsed.truncatingRemainder(dividingBy: 60) / 60
        }
        return elapsed.truncatingRemainder(dividingBy: 3600) / 3600
    }

    var spentToday: Int {
        let cal = Calendar.current
        return history
            .filter { cal.isDateInToday($0.endedAt ?? $0.startedAt) }
            .reduce(0) { $0 + $1.cost() }
    }

    // MARK: - Aksi

    func start() {
        guard active == nil else { return }
        let ticket = ParkingTicket(
            startedAt: Date(),
            ratePerHour: ratePerHour,
            mode: mode,
            location: location.trimmingCharacters(in: .whitespaces),
            plate: plate.trimmingCharacters(in: .whitespaces).uppercased()
        )
        active = ticket
        now = Date()
        save()
        Haptic.thud()
        beginActivity(for: ticket)
    }

    @discardableResult
    func stop() -> ParkingTicket? {
        guard var ticket = active else { return nil }
        ticket.endedAt = Date()
        active = nil
        history.insert(ticket, at: 0)
        if history.count > 60 { history.removeLast(history.count - 60) }
        save()
        Haptic.ok()
        endActivity(final: ticket)
        return ticket
    }

    func clearHistory() {
        history.removeAll()
        save()
    }

    // MARK: - Detak

    private func tick(_ date: Date) {
        now = date
        guard let a = active else { return }
        let cost = Billing.cost(elapsed: date.timeIntervalSince(a.startedAt),
                                ratePerHour: a.ratePerHour, mode: a.mode)
        if cost != lastPushedCost {
            if lastPushedCost >= 0 && cost > lastPushedCost { Haptic.tick() }
            pushActivity(cost: cost)
        } else if date.timeIntervalSince(lastPushedAt) > 60 {
            // jaga-jaga supaya kartu di layar kunci tidak dianggap basi
            pushActivity(cost: cost)
        }
    }

    // MARK: - Live Activity

    private func contentState(cost: Int) -> ParkirAttributes.ContentState? {
        guard let a = active else { return nil }
        let next = Billing.nextTick(start: a.startedAt, now: now,
                                    ratePerHour: a.ratePerHour, mode: a.mode)
        return .init(startedAt: a.startedAt,
                     ratePerHour: a.ratePerHour,
                     mode: a.mode,
                     costNow: cost,
                     nextTickAt: next?.at,
                     nextTickCost: next?.cost)
    }

    private func beginActivity(for ticket: ParkingTicket) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard let state = contentState(cost: ticket.cost(at: ticket.startedAt)) else { return }
        let attrs = ParkirAttributes(
            location: ticket.location.isEmpty ? "Parkir" : ticket.location,
            plate: ticket.plate
        )
        do {
            activity = try Activity.request(
                attributes: attrs,
                content: .init(state: state, staleDate: Date().addingTimeInterval(180)),
                pushType: nil
            )
            lastPushedCost = state.costNow
            lastPushedAt = Date()
        } catch {
            activity = nil
        }
    }

    private func pushActivity(cost: Int) {
        lastPushedCost = cost
        lastPushedAt = Date()
        guard let activity, let state = contentState(cost: cost) else { return }
        Task {
            await activity.update(.init(state: state,
                                        staleDate: Date().addingTimeInterval(180)))
        }
    }

    private func endActivity(final ticket: ParkingTicket) {
        guard let activity else { return }
        let state = ParkirAttributes.ContentState(
            startedAt: ticket.startedAt,
            ratePerHour: ticket.ratePerHour,
            mode: ticket.mode,
            costNow: ticket.cost(),
            nextTickAt: nil,
            nextTickCost: nil
        )
        self.activity = nil
        lastPushedCost = -1
        Task {
            await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .immediate)
        }
    }

    /// Dipanggil saat app dibuka lagi. Tiga kemungkinan:
    /// masih ada sesi dan kartunya hidup (sambungkan), sesi masih ada tapi
    /// kartunya sudah hilang (buat ulang), atau tidak ada sesi tapi kartunya
    /// nyangkut (tutup).
    private func reattachActivity() {
        activity = Activity<ParkirAttributes>.activities.first

        if let ticket = active {
            if let live = activity {
                lastPushedCost = live.content.state.costNow
                lastPushedAt = Date()
            } else {
                beginActivity(for: ticket)
            }
        } else if let stale = activity {
            Task { await stale.end(nil, dismissalPolicy: .immediate) }
            activity = nil
        }
    }

    // MARK: - Simpan

    private func save() {
        let enc = JSONEncoder()
        let d = UserDefaults.standard
        d.set(try? enc.encode(active), forKey: activeKey)
        d.set(try? enc.encode(history), forKey: historyKey)
    }

    private func persistPrefs() {
        let d = UserDefaults.standard
        d.set(ratePerHour, forKey: "pref.rate")
        d.set(mode.rawValue, forKey: "pref.mode")
        d.set(location, forKey: "pref.location")
        d.set(plate, forKey: "pref.plate")
    }

    private func loadPrefs() {
        let d = UserDefaults.standard
        if d.object(forKey: "pref.rate") != nil { ratePerHour = d.integer(forKey: "pref.rate") }
        if let raw = d.string(forKey: "pref.mode"), let m = BillingMode(rawValue: raw) { mode = m }
        location = d.string(forKey: "pref.location") ?? ""
        plate = d.string(forKey: "pref.plate") ?? ""
    }

    private func load() {
        let dec = JSONDecoder()
        let d = UserDefaults.standard
        if let raw = d.data(forKey: activeKey) {
            active = try? dec.decode(ParkingTicket?.self, from: raw)
        }
        if let raw = d.data(forKey: historyKey) {
            history = (try? dec.decode([ParkingTicket].self, from: raw)) ?? []
        }
    }
}
