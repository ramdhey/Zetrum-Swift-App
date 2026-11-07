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
    }

    var stationName: String
    var stationArea: String
    var connector: String
    var powerLabel: String
    var carName: String
}
