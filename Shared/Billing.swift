import Foundation

/// Cara tarif dihitung. Di Indonesia dua-duanya umum:
/// tukang parkir biasanya membulatkan ke atas per jam, aplikasi mall sering pro-rata.
enum BillingMode: String, Codable, CaseIterable, Identifiable {
    case hourly   // dibulatkan ke atas tiap jam
    case prorata  // dihitung per menit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hourly: return "Per jam"
        case .prorata: return "Pro-rata"
        }
    }

    var blurb: String {
        switch self {
        case .hourly: return "Lewat semenit, hitung sejam"
        case .prorata: return "Dihitung per menit jalan"
        }
    }
}

/// Satu-satunya tempat rumus biaya hidup. Dipakai app dan Live Activity
/// supaya angka di layar kunci tidak pernah beda dengan angka di app.
enum Billing {

    static func cost(elapsed: TimeInterval, ratePerHour: Int, mode: BillingMode) -> Int {
        let seconds = max(0, elapsed)
        switch mode {
        case .hourly:
            let blocks = max(1, Int(ceil(seconds / 3600)))
            return blocks * ratePerHour
        case .prorata:
            let raw = seconds / 3600 * Double(ratePerHour)
            // dibulatkan ke 100 perak terdekat, biar tidak ada angka receh aneh
            return Int((raw / 100).rounded()) * 100
        }
    }

    /// Kapan angka di meteran naik berikutnya, dan jadi berapa.
    /// Untuk pro-rata tidak ada "lompatan", jadi nil.
    static func nextTick(start: Date, now: Date, ratePerHour: Int, mode: BillingMode) -> (at: Date, cost: Int)? {
        guard mode == .hourly else { return nil }
        let elapsed = max(0, now.timeIntervalSince(start))
        let blocks = max(1, Int(ceil(elapsed / 3600)))
        let at = start.addingTimeInterval(TimeInterval(blocks) * 3600)
        return (at, (blocks + 1) * ratePerHour)
    }

    static func blocksUsed(elapsed: TimeInterval) -> Int {
        max(1, Int(ceil(max(0, elapsed) / 3600)))
    }
}

enum Rupiah {
    private static let fmt: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.maximumFractionDigits = 0
        return f
    }()

    /// "12.000" — tanpa prefix, karena "Rp" digambar terpisah dengan ukuran sendiri.
    static func plain(_ value: Int) -> String {
        fmt.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func full(_ value: Int) -> String { "Rp " + plain(value) }
}

enum Durasi {
    /// 1:04:09 atau 04:09 kalau belum sejam
    static func clock(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }

    /// "2 jam 14 menit" untuk riwayat
    static func humane(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval))
        let h = total / 3600, m = (total % 3600) / 60
        if h == 0 && m == 0 { return "\(total) detik" }
        if h == 0 { return "\(m) menit" }
        if m == 0 { return "\(h) jam" }
        return "\(h) jam \(m) menit"
    }
}
