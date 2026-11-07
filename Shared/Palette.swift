import SwiftUI

/// Palet diambil dari suasana lahan parkir malam: aspal, lampu sodium,
/// dan kertas struk yang agak kekuningan.
enum Pal {
    static let asphalt      = Color(red: 0.055, green: 0.055, blue: 0.063)
    static let asphaltSoft  = Color(red: 0.094, green: 0.094, blue: 0.106)
    static let slab         = Color(red: 0.129, green: 0.129, blue: 0.141)
    static let line         = Color.white.opacity(0.07)

    static let sodium       = Color(red: 1.00, green: 0.761, blue: 0.294)   // #FFC24B
    static let sodiumDeep   = Color(red: 0.90, green: 0.584, blue: 0.133)
    static let alarm        = Color(red: 0.98, green: 0.353, blue: 0.306)   // #FA5A4E
    static let mint         = Color(red: 0.400, green: 0.886, blue: 0.655)

    static let ink          = Color(red: 0.961, green: 0.945, blue: 0.914)
    static let inkMuted     = Color(red: 0.573, green: 0.553, blue: 0.518)
    static let inkFaint     = Color(red: 0.333, green: 0.325, blue: 0.314)

    static let receipt      = Color(red: 0.957, green: 0.937, blue: 0.890)
    static let receiptInk   = Color(red: 0.141, green: 0.133, blue: 0.118)
}

extension Font {
    /// Angka besar: lebar digit dikunci supaya tidak goyang tiap detik.
    static func meter(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
    static func label(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct Stencil: ViewModifier {
    var size: CGFloat = 11
    var tracking: CGFloat = 1.6
    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .bold, design: .rounded))
            .tracking(tracking)
            .textCase(.uppercase)
    }
}

extension View {
    /// Teks kecil huruf besar berjarak — seperti sablon di rambu parkir.
    func stencil(_ size: CGFloat = 11, tracking: CGFloat = 1.6) -> some View {
        modifier(Stencil(size: size, tracking: tracking))
    }

    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value { transform(self, value) } else { self }
    }
}
