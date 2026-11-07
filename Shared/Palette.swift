import SwiftUI

/// Zetrum: hitam dingin seperti dasbor mobil yang mati, satu warna setrum,
/// dan biru es untuk apa pun yang berhubungan dengan waktu.
enum Pal {
    static let void        = Color(red: 0.039, green: 0.043, blue: 0.051)
    static let surface     = Color(red: 0.063, green: 0.071, blue: 0.082)
    static let slab        = Color(red: 0.090, green: 0.102, blue: 0.118)
    static let line        = Color.white.opacity(0.07)

    static let volt        = Color(red: 0.765, green: 0.961, blue: 0.235)   // #C3F53C
    static let voltDeep    = Color(red: 0.561, green: 0.749, blue: 0.122)
    static let ion         = Color(red: 0.435, green: 0.890, blue: 1.000)   // #6FE3FF
    static let alarm       = Color(red: 1.000, green: 0.420, blue: 0.353)

    static let ink         = Color(red: 0.949, green: 0.957, blue: 0.937)
    static let inkMuted    = Color(red: 0.529, green: 0.557, blue: 0.584)
    static let inkFaint    = Color(red: 0.302, green: 0.325, blue: 0.353)

    static let receipt     = Color(red: 0.957, green: 0.961, blue: 0.945)
    static let receiptInk  = Color(red: 0.071, green: 0.082, blue: 0.098)
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
    /// Teks kecil huruf besar berjarak — seperti label di panel pengisian.
    func stencil(_ size: CGFloat = 11, tracking: CGFloat = 1.6) -> some View {
        modifier(Stencil(size: size, tracking: tracking))
    }

    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value { transform(self, value) } else { self }
    }
}

// MARK: - Tanda Zetrum

/// Kilat Zetrum. Digambar sendiri, bukan simbol sistem, supaya sudutnya
/// tetap tajam di ukuran sekecil apa pun di Dynamic Island.
struct Bolt: Shape {
    func path(in rect: CGRect) -> Path {
        let pts: [(CGFloat, CGFloat)] = [
            (0.635, 0.00), (0.165, 0.565), (0.435, 0.565),
            (0.345, 1.00), (0.845, 0.405), (0.555, 0.405)
        ]
        var p = Path()
        for (i, pt) in pts.enumerated() {
            let c = CGPoint(x: rect.minX + pt.0 * rect.width,
                            y: rect.minY + pt.1 * rect.height)
            i == 0 ? p.move(to: c) : p.addLine(to: c)
        }
        p.closeSubpath()
        return p
    }
}

/// Kilat di dalam keping — dipakai di header, di baris stasiun, dan di
/// Dynamic Island.
struct BoltMark: View {
    var size: CGFloat = 28
    var tint: Color = Pal.volt
    var filled: Bool = true

    var body: some View {
        Bolt()
            .fill(filled ? Pal.void : tint)
            .frame(width: size * 0.46, height: size * 0.62)
            .frame(width: size, height: size)
            .background {
                if filled {
                    RoundedRectangle(cornerRadius: size * 0.30, style: .continuous).fill(tint)
                } else {
                    RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                        .stroke(tint.opacity(0.4), lineWidth: 1)
                }
            }
    }
}

// MARK: - Pak baterai

/// Deretan sel seperti indikator baterai di dasbor mobil, bukan batang polos.
///
/// Dua cara menunjukkan arus sedang masuk, karena keduanya tidak bisa dipakai
/// di tempat yang sama:
///
/// - Di dalam aplikasi, sel paling depan berdenyut (`pulse`).
/// - Di Live Activity, animasi berulang tidak dijalankan sistem sama sekali,
///   jadi `pulse` dimatikan dan yang dipakai isian separuh sel terdepan —
///   tingginya ikut pecahan persen, jadi tiap kabar baru datang selnya
///   terlihat bertambah, bukan melompat.
struct BatteryPack: View {
    var soc: Double
    var target: Double
    var tint: Color = Pal.volt
    var charging: Bool = true
    /// Matikan di widget: denyut berulang tidak jalan di Live Activity dan
    /// malah membekukan sel terdepan di opasitas sembarang.
    var pulse: Bool = true
    var cells: Int = 24
    var height: CGFloat = 34

    @State private var breathe = false

    private var filled: Double { max(0, min(100, soc)) / 100 * Double(cells) }

    var body: some View {
        GeometryReader { geo in
            let gap: CGFloat = 3
            let w = (geo.size.width - gap * CGFloat(cells - 1)) / CGFloat(cells)
            let head = Int(filled.rounded(.down))
            let frac = filled - filled.rounded(.down)

            ZStack(alignment: .leading) {
                HStack(spacing: gap) {
                    ForEach(0..<cells, id: \.self) { i in
                        cell(i, head: head, frac: frac)
                            .frame(width: w)
                    }
                }
                // penanda target
                if target < 99.5 {
                    Rectangle()
                        .fill(Pal.ink.opacity(0.65))
                        .frame(width: 1.5, height: height + 7)
                        .offset(x: (geo.size.width + gap) * (target / 100) - gap / 2)
                }
            }
            .frame(height: height)
            .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: breathe)
            // tiap kabar baru datang, selnya menyala berangsur, tidak kedip
            .animation(.easeOut(duration: 0.55), value: soc)
            .animation(.easeInOut(duration: 0.6), value: tint)
            .onAppear { breathe = pulse && charging }
            .onChange(of: charging) { _, now in breathe = pulse && now }
        }
        .frame(height: height + 7)
    }

    @ViewBuilder
    private func cell(_ i: Int, head: Int, frac: Double) -> some View {
        let shape = RoundedRectangle(cornerRadius: 2.5, style: .continuous)
        if i < head {
            shape.fill(tint)
        } else if i == head {
            // sel terdepan: terisi sebagian dari bawah, sisanya redup
            shape
                .fill(tint.opacity(pulse ? 0.55 : 0.22))
                .overlay(alignment: .bottom) {
                    shape.fill(tint).frame(height: height * max(0.12, frac))
                }
                .opacity(charging && pulse && breathe ? 0.3 : 1)
        } else {
            shape.fill(Pal.slab)
        }
    }
}
