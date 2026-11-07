import SwiftUI

/// Angka yang berguling seperti meteran listrik: tiap digit punya animasinya
/// sendiri, jadi cuma kolom yang berubah yang bergerak.
struct Odometer: View {
    var value: Int
    var size: CGFloat
    var weight: Font.Weight = .bold
    var color: Color = Pal.ink

    private var digits: [(id: Int, ch: Character)] {
        let s = Rupiah.plain(value)
        // id dihitung dari kanan supaya digit satuan tetap "kolom yang sama"
        // walau jumlah digit bertambah (999 -> 1.000).
        return Array(s).enumerated().map { (s.count - $0.offset, $0.element) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(digits, id: \.id) { item in
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
                        .padding(.horizontal, size * 0.01)
                }
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.72), value: value)
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
            Odometer(value: value, size: size, color: color)
        }
    }
}
