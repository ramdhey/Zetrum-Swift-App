import SwiftUI

@main
struct ZetrumApp: App {
    @StateObject private var store = ChargeStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
