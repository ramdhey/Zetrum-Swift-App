import SwiftUI

/// Bentuk karcis: sudut membulat dengan dua takikan sobek di kiri-kanan.
/// `notchY` dihitung dalam poin dari sisi atas, supaya takikannya bisa
/// dipasang tepat sejajar dengan garis perforasi berapa pun tinggi kartunya.
struct TicketShape: Shape {
    var notchY: CGFloat
    var notchRadius: CGFloat = 11
    var corner: CGFloat = 22

    var animatableData: CGFloat {
        get { notchY }
        set { notchY = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let base = Path(roundedRect: rect, cornerRadius: corner)
        let y = rect.minY + notchY
        guard notchY > corner, y < rect.maxY - corner else { return base }
        var cut = Path()
        cut.addEllipse(in: CGRect(x: rect.minX - notchRadius, y: y - notchRadius,
                                  width: notchRadius * 2, height: notchRadius * 2))
        cut.addEllipse(in: CGRect(x: rect.maxX - notchRadius, y: y - notchRadius,
                                  width: notchRadius * 2, height: notchRadius * 2))
        return base.subtracting(cut)
    }
}

/// Dilapor oleh `Perforation` supaya kartu tahu di mana harus menakik dirinya.
struct PerforationY: PreferenceKey {
    static let defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

/// Garis putus-putus tempat karcis disobek.
struct Perforation: View {
    var color: Color = Pal.inkFaint

    var body: some View {
        Line()
            .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [2, 5]))
            .foregroundStyle(color)
            .frame(height: 1)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: PerforationY.self,
                        value: geo.frame(in: .named("ticket")).midY
                    )
                }
            )
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return p
        }
    }
}

/// Kartu berbentuk karcis yang takikannya otomatis mengikuti garis sobek
/// di dalamnya.
struct TicketCard<Content: View>: View {
    var fill: Color = Pal.asphaltSoft
    var stroke: Color = Pal.line
    var corner: CGFloat = 22
    @ViewBuilder var content: Content

    @State private var notch: CGFloat = 0

    var body: some View {
        content
            .coordinateSpace(name: "ticket")
            .background {
                let shape = TicketShape(notchY: notch, corner: corner)
                shape
                    .fill(fill)
                    .overlay(shape.stroke(stroke, lineWidth: 1))
            }
            .onPreferenceChange(PerforationY.self) { y in
                notch = y ?? 0
            }
    }
}
