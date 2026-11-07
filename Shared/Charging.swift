import Foundation

// MARK: - Soket

enum Connector: String, Codable, Hashable {
    case dc   // CCS2, pengisian cepat
    case ac   // Type 2, pengisian lambat

    var label: String { self == .dc ? "DC CCS2" : "AC Type 2" }

    /// Seberapa jauh daya turun saat baterai mendekati penuh.
    /// Pengisian cepat melandai tajam di atas 80%; AC hampir tidak.
    var taperFloor: Double { self == .dc ? 0.18 : 0.60 }
}

// MARK: - SPKLU Zetrum

struct Station: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var area: String
    var connector: Connector
    var ratedKW: Double
    var ratePerKwh: Int

    var powerLabel: String {
        let s = ratedKW.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(ratedKW))
            : String(format: "%.1f", ratedKW).replacingOccurrences(of: ".", with: ",")
        return s + " kW"
    }

    static let all: [Station] = [
        .init(id: "home",     name: "Zetrum Home",        area: "Pengisian di rumah",
              connector: .ac, ratedKW: 7.4,  ratePerKwh: 1_450),
        .init(id: "sutera",   name: "Zetrum Alam Sutera", area: "Tangerang Selatan",
              connector: .ac, ratedKW: 22,   ratePerKwh: 1_650),
        .init(id: "senayan",  name: "Zetrum Senayan",     area: "Jakarta Pusat",
              connector: .dc, ratedKW: 60,   ratePerKwh: 2_475),
        .init(id: "kuningan", name: "Zetrum Kuningan",    area: "Jakarta Selatan",
              connector: .dc, ratedKW: 120,  ratePerKwh: 2_475),
        .init(id: "km57",     name: "Zetrum Rest Area 57",area: "Tol Jakarta–Cikampek",
              connector: .dc, ratedKW: 200,  ratePerKwh: 3_700),
    ]

    static let fallback = Station.all[2]
}

// MARK: - Perhitungan pengisian

/// Daya pengisian tidak rata: penuh sampai 80%, lalu melandai supaya sel
/// tidak rusak. Semua rumus di sini punya bentuk tertutup — artinya waktu
/// selesai bisa dihitung sekali di depan, lalu Live Activity tinggal
/// menghitung mundur ke tanggal itu tanpa perlu dibangunkan terus.
///
/// Di bawah titik landai:   dSoC/dt = A
/// Di atasnya:              dSoC/dt = A · (1 − b·u),  u = SoC − 80
/// Jawabannya:              u(t) = (1/b)·(1 − e^(−A·b·t))
enum Charge {

    static let knee: Double = 80

    struct Plan: Codable, Hashable {
        var capacityKWh: Double
        var startSoC: Double
        var targetSoC: Double
        var ratedKW: Double
        var taperFloor: Double
        var ratePerKwh: Int

        /// Persen per jam saat daya penuh.
        var a: Double { capacityKWh > 0 ? 100 * ratedKW / capacityKWh : 0 }
        /// Kecuraman pelandaian.
        var b: Double { (1 - taperFloor) / (100 - Charge.knee) }
        /// Batas atas teoretis kurva; selalu di atas 100 selama taperFloor > 0.
        var ceiling: Double { Charge.knee + 1 / b }
    }

    // MARK: Persen baterai pada detik ke-t

    static func soc(_ p: Plan, after elapsed: TimeInterval) -> Double {
        let t = max(0, elapsed) / 3600
        guard p.a > 0 else { return p.startSoC }
        let target = min(100, p.targetSoC)

        if p.startSoC >= knee {
            return min(target, knee + taperedU(p, from: p.startSoC - knee, hours: t))
        }
        let tKnee = (knee - p.startSoC) / p.a
        if t <= tKnee { return min(target, p.startSoC + p.a * t) }
        return min(target, knee + taperedU(p, from: 0, hours: t - tKnee))
    }

    private static func taperedU(_ p: Plan, from u0: Double, hours t: Double) -> Double {
        let inv = 1 / p.b
        return inv - (inv - u0) * exp(-p.a * p.b * t)
    }

    // MARK: Waktu untuk mencapai persen tertentu

    /// Nil kalau tidak akan pernah tercapai (kurva melandai di bawahnya).
    static func time(_ p: Plan, toReach s: Double) -> TimeInterval? {
        guard p.a > 0, s > p.startSoC else { return 0 }
        let goal = min(s, 100)

        if goal <= knee {
            return (goal - p.startSoC) / p.a * 3600
        }
        let tKnee = p.startSoC >= knee ? 0 : (knee - p.startSoC) / p.a
        let u0 = max(0, p.startSoC - knee)
        let u = goal - knee
        let inv = 1 / p.b
        guard u < inv else { return nil }
        let t = -log((inv - u) / (inv - u0)) / (p.a * p.b)
        return (tKnee + t) * 3600
    }

    // MARK: Turunan lain

    static func energy(_ p: Plan, at soc: Double) -> Double {
        max(0, soc - p.startSoC) / 100 * p.capacityKWh
    }

    static func cost(_ p: Plan, at soc: Double) -> Int {
        let raw = energy(p, at: soc) * Double(p.ratePerKwh)
        return Int((raw / 50).rounded()) * 50      // dibulatkan ke 50 perak
    }

    /// Daya yang mengalir sekarang, sudah ikut melandai.
    static func power(_ p: Plan, at soc: Double) -> Double {
        guard soc > knee else { return p.ratedKW }
        let f = max(p.taperFloor, 1 - (1 - p.taperFloor) * (soc - knee) / (100 - knee))
        return p.ratedKW * f
    }

    static func isDone(_ p: Plan, at soc: Double) -> Bool {
        soc >= min(100, p.targetSoC) - 0.05
    }
}
