import SwiftUI

/// Angka yang berguling seperti meteran listrik: tiap digit punya animasinya
/// sendiri, jadi cuma kolom yang berubah yang bergerak.
struct Odometer: View {
    var text: String
    var size: CGFloat
    var weight: Font.Weight = .bold
    var color: Color = Pal.ink

    /// Nomor kolom dihitung dari kanan, supaya digit satuan tetap kolom yang
    /// sama walau jumlah angkanya bertambah (999 jadi 1.000).
    private var glyphs: [(id: Int, ch: Character)] {
        Array(text).enumerated().map { (text.count - $0.offset, $0.element) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(glyphs, id: \.id) { item in
                if item.ch.isNumber {
                    Text(String(item.ch))
                        .font(.meter(size, weight))
                        .foregroundStyle(color)
                        .contentTransition(.numericText(countsDown: false))
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                } else {
                    Text(String(item.ch))
                        .font(.meter(size * 0.86, weight))
                        .foregroundStyle(color.opacity(0.68))
                }
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.72), value: text)
    }
}

/// "Rp" kecil + angka besar, rata bawah.
struct PriceTag: View {
    var value: Int
    var size: CGFloat
    var color: Color = Pal.ink

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: size * 0.13) {
            Text("Rp")
                .font(.label(size * 0.34, .semibold))
                .foregroundStyle(color.opacity(0.55))
            Odometer(text: Rupiah.plain(value), size: size, color: color)
        }
    }
}

/// Angka dengan satuan di belakangnya, misal "24,8 kWh".
struct UnitTag: View {
    var text: String
    var unit: String
    var size: CGFloat
    var color: Color = Pal.ink

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: size * 0.14) {
            Odometer(text: text, size: size, color: color)
            Text(unit)
                .font(.label(size * 0.36, .semibold))
                .foregroundStyle(color.opacity(0.55))
        }
    }
}
