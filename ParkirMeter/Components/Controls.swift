import SwiftUI

/// Tombol utama. Sengaja berat dan lebar, ditekan sampai amblas sedikit.
struct SlabButton<Label: View>: View {
    var tint: Color = Pal.sodium
    var action: () -> Void
    @ViewBuilder var label: Label
    @State private var down = false

    var body: some View {
        Button {
            action()
        } label: {
            label
                .frame(maxWidth: .infinity)
                .padding(.vertical, 19)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tint)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        .blendMode(.overlay)
                )
                .shadow(color: tint.opacity(down ? 0.1 : 0.32), radius: down ? 6 : 18, y: down ? 2 : 8)
                .scaleEffect(down ? 0.975 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !down { down = true } }
                .onEnded { _ in down = false }
        )
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: down)
    }
}

/// Tahan untuk mengakhiri. Biar tidak kepencet waktu HP di kantong.
struct HoldToConfirm: View {
    var title: String
    var tint: Color = Pal.alarm
    var duration: Double = 0.9
    var action: () -> Void

    @State private var progress: Double = 0
    @State private var holding = false
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Pal.slab)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint)
                    .frame(width: geo.size.width * progress)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 9) {
                Image(systemName: holding ? "hand.tap.fill" : "flag.checkered")
                    .font(.system(size: 13, weight: .bold))
                Text(holding ? "Tahan terus…" : title).stencil(12, tracking: 1.4)
            }
            .foregroundStyle(progress > 0.55 ? Pal.asphalt : Pal.ink)
        }
        .frame(height: 58)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.45), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !holding { begin() } }
                .onEnded { _ in cancel() }
        )
        .animation(.easeOut(duration: 0.18), value: holding)
    }

    private func begin() {
        holding = true
        Haptic.tick()
        timer?.invalidate()
        let step = 0.02
        timer = Timer.scheduledTimer(withTimeInterval: step, repeats: true) { t in
            Task { @MainActor in
                progress = min(1, progress + step / duration)
                if progress >= 1 {
                    t.invalidate()
                    holding = false
                    progress = 0
                    action()
                }
            }
        }
    }

    private func cancel() {
        timer?.invalidate()
        holding = false
        withAnimation(.easeOut(duration: 0.22)) { progress = 0 }
    }
}

/// Pilihan tarif berbentuk kepingan, seperti koin yang dimasukkan ke meteran.
struct RateChip: View {
    var value: Int
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(Rupiah.plain(value))
                    .font(.meter(17, .bold))
                Text("/jam")
                    .font(.label(9, .semibold))
                    .opacity(0.6)
            }
            .foregroundStyle(selected ? Pal.asphalt : Pal.ink)
            .frame(width: 74, height: 54)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(selected ? Pal.sodium : Pal.slab)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(selected ? .clear : Pal.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Field tanpa kotak — cuma garis bawah, seperti isian di karcis.
struct RuledField: View {
    var caption: String
    var placeholder: String
    @Binding var text: String
    var uppercase: Bool = false
    var width: CGFloat? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(caption).stencil(9.5, tracking: 1.3).foregroundStyle(Pal.inkMuted)
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Pal.inkFaint))
                .font(.label(17, .semibold))
                .foregroundStyle(Pal.ink)
                .textInputAutocapitalization(uppercase ? .characters : .words)
                .autocorrectionDisabled()
                .tint(Pal.sodium)
            Rectangle().fill(Pal.line).frame(height: 1)
        }
        .ifLet(width) { $0.frame(width: $1) }
    }
}
