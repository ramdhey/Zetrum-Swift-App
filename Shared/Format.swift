import Foundation

/// Semua angka di sini ikut bahasa yang sedang dipakai: Indonesia menulis
/// `2.466,78`, Inggris menulis `2,466.78`. Mata uangnya tetap rupiah —
/// listriknya memang dijual di Indonesia, yang berubah cuma cara menulis
/// angkanya.
private func marks() -> (group: String, decimal: String) {
    (Loc.lang.groupMark, Loc.lang.decimalMark)
}

enum Rupiah {
    private static func fmt(_ min: Int, _ max: Int) -> NumberFormatter {
        let m = marks()
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = m.group
        f.decimalSeparator = m.decimal
        f.minimumFractionDigits = min
        f.maximumFractionDigits = max
        return f
    }

    /// "112.000" — tanpa prefix, karena "Rp" digambar terpisah dengan ukuran sendiri.
    static func plain(_ value: Int) -> String {
        fmt(0, 0).string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func full(_ value: Int) -> String { "Rp " + plain(value) }

    /// "Rp 2.466,78" — tarif per kWh memang pakai sen.
    static func decimal(_ value: Double) -> String {
        "Rp " + (fmt(2, 2).string(from: NSNumber(value: value)) ?? "\(value)")
    }
}

enum Energi {
    /// "24,8" di Indonesia, "24.8" di Inggris.
    static func kwh(_ value: Double, decimals: Int = 1) -> String {
        let s = String(format: "%.\(decimals)f", max(0, value))
        return s.replacingOccurrences(of: ".", with: Loc.lang.decimalMark)
    }

    static func persen(_ value: Double) -> String { String(Int(value.rounded(.down))) }
}

enum Daya {
    /// "7,4" atau "120" — angka bulat tidak diberi koma nol.
    static func kw(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value).replacingOccurrences(of: ".", with: Loc.lang.decimalMark)
    }
}

enum Jarak {
    /// "1,3 km" atau "840 m"
    static func near(_ km: Double) -> String {
        km < 1
            ? "\(Int((km * 1000).rounded())) m"
            : String(format: "%.1f", km)
                .replacingOccurrences(of: ".", with: Loc.lang.decimalMark) + " km"
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
        if h == 0 && m == 0 { return T("dur.underMinute") }
        if h == 0 { return T("dur.minutes", m) }
        if m == 0 { return T("dur.hours", h) }
        return T("dur.hoursMinutes", h, m)
    }

    /// "2j 14m" untuk tempat sempit
    static func tight(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval).rounded())
        let h = total / 3600, m = (total % 3600) / 60
        return h == 0 ? T("dur.tightMinutes", m) : T("dur.tightHours", h, m)
    }
}

/// Tanggal dan jam, selalu mengikuti bahasa yang sedang dipakai.
enum Tanggal {
    private static func fmt(_ pattern: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Loc.lang.locale
        f.dateFormat = pattern
        return f
    }

    /// "November 2026"
    static func month(_ d: Date = Date()) -> String { fmt("MMMM yyyy").string(from: d) }
    /// "NOV"
    static func shortMonth(_ d: Date) -> String { fmt("MMM").string(from: d).uppercased() }
    /// "7 Nov, 20:41"
    static func stamp(_ d: Date) -> String { fmt("d MMM, HH:mm").string(from: d) }
    /// "7 Nov 2026, 20:41"
    static func longStamp(_ d: Date) -> String { fmt("d MMM yyyy, HH:mm").string(from: d) }
    /// "20:41"
    static func clock(_ d: Date = Date()) -> String { fmt("HH:mm").string(from: d) }
}
