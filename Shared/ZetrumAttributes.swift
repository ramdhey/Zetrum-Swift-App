import ActivityKit
import Foundation

/// Dipakai oleh dua target sekaligus (app + widget extension).
struct ZetrumAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var plan: Charge.Plan
        var startedAt: Date
        /// Keadaan saat kabar terakhir dikirim.
        var soc: Double
        var energy: Double
        var cost: Int
        var power: Double
        /// Dihitung sekali di depan, jadi hitung mundurnya tetap jalan
        /// di layar kunci walau aplikasi sedang tidur.
        var finishAt: Date?
        var isDone: Bool
        /// Bahasa yang dipakai pemiliknya. Widget jalan di proses lain dan
        /// tidak bisa membaca pengaturan aplikasi, jadi bahasanya ikut
        /// menumpang kabar ini — artinya ganti bahasa di tengah pengisian
        /// langsung terbawa ke kartu layar kunci.
        var lang: String = Lang.indonesian.rawValue
    }

    var stationName: String
    var stationArea: String
    var connector: String
    var powerLabel: String
    var carName: String
    var isBike: Bool
}
