import SwiftUI

@main
struct ZetrumApp: App {
    @StateObject private var store = ChargeStore()

    var body: some Scene {
        WindowGroup {
            ShellView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
