import ActivityKit
import Foundation

/// Dipakai oleh dua target sekaligus (app + widget extension).
struct ParkirAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startedAt: Date
        var ratePerHour: Int
        var mode: BillingMode
        /// Biaya saat update terakhir dikirim. Widget memakai ini sebagai dasar,
        /// lalu menghitung sendiri lompatan berikutnya lewat `nextTickAt`.
        var costNow: Int
        var nextTickAt: Date?
        var nextTickCost: Int?
    }

    var location: String
    var plate: String
}
