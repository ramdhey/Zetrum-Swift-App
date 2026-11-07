import Foundation

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

    /// Ini aplikasi contoh, bukan meteran SPKLU sungguhan: mengisi mobil
    /// betulan makan berjam-jam dan tidak ada yang mau menontonnya. Jam
    /// dindingnya dipadatkan segini. Daya, kWh dan rupiahnya tidak ikut —
    /// semuanya diturunkan dari persen baterai, bukan dari jam.
    static let demoSpeed: Double = 60

    struct Plan: Codable, Hashable {
        var capacityKWh: Double
        var startSoC: Double
        var targetSoC: Double
        /// Daya yang betul-betul mengalir: yang terkecil antara kemampuan
        /// charger dan kemampuan mobilnya menerima.
        var ratedKW: Double
        var taperFloor: Double
        var ratePerKwh: Double
        var serviceFee: Int
        /// Pemadat waktu. Tetap 1 untuk tabel spesifikasi yang memang
        /// harus menyebut durasi sungguhan; sesi pengisian memakai
        /// `Charge.demoSpeed`.
        var speed: Double = 1

        /// Persen per jam saat daya penuh.
        var a: Double { capacityKWh > 0 ? 100 * ratedKW / capacityKWh : 0 }
        /// Kecuraman pelandaian.
        var b: Double { (1 - taperFloor) / (100 - Charge.knee) }
        /// Batas atas teoretis kurva; selalu di atas 100 selama taperFloor > 0.
        var ceiling: Double { Charge.knee + 1 / b }
    }

    // MARK: Persen baterai pada detik ke-t

    static func soc(_ p: Plan, after elapsed: TimeInterval) -> Double {
        let t = max(0, elapsed) * max(1, p.speed) / 3600
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
        // jam dinding = waktu seharusnya dibagi pemadat
        let scale = 3600 / max(1, p.speed)

        if goal <= knee {
            return (goal - p.startSoC) / p.a * scale
        }
        let tKnee = p.startSoC >= knee ? 0 : (knee - p.startSoC) / p.a
        let u0 = max(0, p.startSoC - knee)
        let u = goal - knee
        let inv = 1 / p.b
        guard u < inv else { return nil }
        let t = -log((inv - u) / (inv - u0)) / (p.a * p.b)
        return (tKnee + t) * scale
    }

    // MARK: Turunan lain

    static func energy(_ p: Plan, at soc: Double) -> Double {
        max(0, soc - p.startSoC) / 100 * p.capacityKWh
    }

    /// Biaya listrik saja, belum termasuk biaya layanan.
    static func energyCost(_ p: Plan, at soc: Double) -> Int {
        let raw = energy(p, at: soc) * p.ratePerKwh
        return Int((raw / 50).rounded()) * 50      // dibulatkan ke 50 perak
    }

    /// Yang betul-betul dibayar.
    static func cost(_ p: Plan, at soc: Double) -> Int {
        energyCost(p, at: soc) + (energy(p, at: soc) > 0 ? p.serviceFee : 0)
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
