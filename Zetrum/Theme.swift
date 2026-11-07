import SwiftUI

/// Latar dasbor: hitam dingin, satu sapuan setrum di pojok, dan kilat
/// Zetrum samar sebagai cap.
struct DashBackground: View {
    var warm: Color = Pal.volt

    var body: some View {
        ZStack {
            Pal.void
            RadialGradient(
                colors: [warm.opacity(0.13), .clear],
                center: .init(x: 0.12, y: -0.06),
                startRadius: 6, endRadius: 460
            )
            RadialGradient(
                colors: [Pal.ion.opacity(0.06), .clear],
                center: .init(x: 1.02, y: 0.78),
                startRadius: 4, endRadius: 360
            )
            Bolt()
                .fill(warm.opacity(0.022))
                .frame(width: 210, height: 290)
                .rotationEffect(.degrees(-12))
                .offset(x: 120, y: -120)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .ignoresSafeArea()
    }
}

/// Getaran halus — bukan dekorasi, ini yang bikin perubahan angka terasa.
enum Haptic {
    static func tick() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.55)
    }
    static func thud() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    static func ok() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
