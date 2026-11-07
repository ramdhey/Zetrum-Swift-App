import Foundation

enum Rupiah {
    private static func fmt(_ min: Int, _ max: Int) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.decimalSeparator = ","
        f.minimumFractionDigits = min
        f.maximumFractionDigits = max
        return f
    }
    private static let whole = fmt(0, 0)
    private static let cents = fmt(2, 2)

    /// "112.000" — tanpa prefix, karena "Rp" digambar terpisah dengan ukuran sendiri.
    static func plain(_ value: Int) -> String {
        whole.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func full(_ value: Int) -> String { "Rp " + plain(value) }

    /// "Rp 2.466,78" — tarif per kWh memang pakai sen.
    static func decimal(_ value: Double) -> String {
        "Rp " + (cents.string(from: NSNumber(value: value)) ?? "\(value)")
    }
}

enum Energi {
    /// "24,8" — koma desimal, cara Indonesia.
    static func kwh(_ value: Double, decimals: Int = 1) -> String {
        String(format: "%.\(decimals)f", max(0, value)).replacingOccurrences(of: ".", with: ",")
    }

    static func persen(_ value: Double) -> String { String(Int(value.rounded(.down))) }
}

enum Daya {
    /// "7,4" atau "120" — angka bulat tidak diberi koma nol.
    static func kw(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
    }
}

enum Jarak {
    /// "1,3 km" atau "840 m"
    static func near(_ km: Double) -> String {
        km < 1 ? "\(Int((km * 1000).rounded())) m"
               : String(format: "%.1f", km).replacingOccurrences(of: ".", with: ",") + " km"
    }
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

    /// "2j 14m" untuk tempat sempit
    static func tight(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval).rounded())
        let h = total / 3600, m = (total % 3600) / 60
        return h == 0 ? "\(m)m" : "\(h)j \(m)m"
    }
}
