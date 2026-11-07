import SwiftUI

/// Latar aspal dengan sapuan lampu di pojok atas dan marka kuning samar.
struct AsphaltBackground: View {
    var warm: Color = Pal.sodium
    var body: some View {
        ZStack {
            Pal.asphalt
            RadialGradient(
                colors: [warm.opacity(0.12), .clear],
                center: .init(x: 0.88, y: -0.08),
                startRadius: 8, endRadius: 440
            )
            RadialGradient(
                colors: [Color.white.opacity(0.035), .clear],
                center: .init(x: 0.06, y: 1.05),
                startRadius: 4, endRadius: 320
            )
            HazardStripes()
                .fill(warm.opacity(0.022))
                .frame(height: 120)
                .frame(maxHeight: .infinity, alignment: .top)
                .offset(y: -30)
                .blur(radius: 0.4)
        }
        .ignoresSafeArea()
    }
}

/// Marka serong, seperti zona larangan parkir.
struct HazardStripes: Shape {
    var spacing: CGFloat = 26
    var thickness: CGFloat = 11
    func path(in rect: CGRect) -> Path {
        var p = Path()
        var x = -rect.height
        while x < rect.width + rect.height {
            p.move(to: CGPoint(x: x, y: rect.maxY))
            p.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
            p.addLine(to: CGPoint(x: x + rect.height + thickness, y: rect.minY))
            p.addLine(to: CGPoint(x: x + thickness, y: rect.maxY))
            p.closeSubpath()
            x += spacing
        }
        return p
    }
}

/// Getaran halus waktu angka naik — bukan dekorasi, ini yang bikin deg-degan.
enum Haptic {
    static func tick() {
        let g = UIImpactFeedbackGenerator(style: .rigid)
        g.impactOccurred(intensity: 0.55)
    }
    static func thud() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    static func ok() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
