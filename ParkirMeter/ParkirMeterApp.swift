import SwiftUI

@main
struct ParkirMeterApp: App {
    @StateObject private var store = ParkingStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
