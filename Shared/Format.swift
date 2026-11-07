import Foundation

enum Rupiah {
    private static let fmt: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.maximumFractionDigits = 0
        return f
    }()

    /// "112.000" — tanpa prefix, karena "Rp" digambar terpisah dengan ukuran sendiri.
    static func plain(_ value: Int) -> String {
        fmt.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func full(_ value: Int) -> String { "Rp " + plain(value) }
}

enum Energi {
    /// "24,8" — koma desimal, cara Indonesia.
    static func kwh(_ value: Double, decimals: Int = 1) -> String {
        String(format: "%.\(decimals)f", max(0, value)).replacingOccurrences(of: ".", with: ",")
    }

    static func kw(_ value: Double) -> String {
        value >= 10 ? String(Int(value.rounded())) : kwh(value)
    }

    static func persen(_ value: Double) -> String { String(Int(value.rounded(.down))) }
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

    /// "2 jam 14 menit" untuk riwayat dan perkiraan
    static func humane(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval).rounded())
        let h = total / 3600, m = (total % 3600) / 60
        if h == 0 && m == 0 { return "kurang dari semenit" }
        if h == 0 { return "\(m) menit" }
        if m == 0 { return "\(h) jam" }
        return "\(h) jam \(m) menit"
    }
}
