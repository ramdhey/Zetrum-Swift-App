import SwiftUI

/// Tombol utama. Sengaja berat dan lebar, ditekan sampai amblas sedikit.
struct SlabButton<Label: View>: View {
    var tint: Color = Pal.volt
    var enabled: Bool = true
    var action: () -> Void
    @ViewBuilder var label: Label
    @State private var down = false

    var body: some View {
        Button(action: action) {
            label
                .frame(maxWidth: .infinity)
                .padding(.vertical, 19)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(enabled ? tint : Pal.slab)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        .blendMode(.overlay)
                )
                .shadow(color: tint.opacity(enabled ? (down ? 0.1 : 0.28) : 0),
                        radius: down ? 6 : 18, y: down ? 2 : 8)
                .scaleEffect(down ? 0.975 : 1)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !down && enabled { down = true } }
                .onEnded { _ in down = false }
        )
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: down)
        .animation(.easeOut(duration: 0.2), value: enabled)
    }
}

/// Tahan untuk mencabut. Biar tidak kepencet waktu HP di kantong.
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
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Pal.slab)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint)
                    .frame(width: geo.size.width * progress)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 9) {
                Image(systemName: holding ? "hand.tap.fill" : "powerplug.portrait.slash")
                    .font(.system(size: 13, weight: .bold))
                Text(holding ? "Tahan terus…" : title).stencil(12, tracking: 1.4)
            }
            .foregroundStyle(progress > 0.55 ? Pal.void : Pal.ink)
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
                    t.invalidate(); holding = false; progress = 0; action()
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

/// Geser di atas sel baterai untuk mengatur persen. Lebih cepat daripada
/// mengetik, dan bentuknya sama dengan indikator yang nanti berjalan.
struct SocSlider: View {
    @Binding var value: Double
    var tint: Color = Pal.volt
    var lowerBound: Double = 0
    var cells: Int = 20

    var body: some View {
        GeometryReader { geo in
            let gap: CGFloat = 3
            let w = (geo.size.width - gap * CGFloat(cells - 1)) / CGFloat(cells)
            let head = Int((value / 100 * Double(cells)).rounded(.down))

            HStack(spacing: gap) {
                ForEach(0..<cells, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(i < head ? tint : (Double(i) / Double(cells) * 100 < lowerBound
                                                 ? tint.opacity(0.14) : Pal.slab))
                        .frame(width: w)
                }
            }
            .frame(height: 30)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let f = min(1, max(0, g.location.x / geo.size.width))
                        let v = max(lowerBound, (f * 100).rounded())
                        if v != value { value = v; Haptic.tick() }
                    }
            )
        }
        .frame(height: 30)
    }
}

/// Satu baris SPKLU di daftar pilihan.
struct StationRow: View {
    let station: Station
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                BoltMark(size: 34, tint: selected ? Pal.volt : Pal.inkFaint, filled: selected)

                VStack(alignment: .leading, spacing: 3) {
                    Text(station.name)
                        .font(.label(15, .bold))
                        .foregroundStyle(Pal.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text("\(station.area)  ·  \(station.connector == .dc ? "DC" : "AC")")
                        .font(.label(10.5))
                        .foregroundStyle(Pal.inkMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 10)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(station.powerLabel)
                        .fixedSize()
                        .font(.meter(14, .bold))
                        .foregroundStyle(selected ? Pal.volt : Pal.ink)
                    Text("\(Rupiah.full(station.ratePerKwh))/kWh")
                        .font(.label(10.5))
                        .foregroundStyle(Pal.inkMuted)
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? Pal.volt.opacity(0.09) : Pal.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Pal.volt.opacity(0.5) : Pal.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Angka yang diatur dengan tombol kurang/tambah, untuk kapasitas baterai.
struct NudgeRow: View {
    var caption: String
    var text: String
    var onMinus: () -> Void
    var onPlus: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(caption).stencil(9.5, tracking: 1.3).foregroundStyle(Pal.inkMuted)
                Text(text).font(.meter(17, .bold)).foregroundStyle(Pal.ink)
            }
            Spacer()
            HStack(spacing: 0) {
                button("minus", onMinus)
                Divider().frame(height: 20).overlay(Pal.line)
                button("plus", onPlus)
            }
            .frame(height: 42)
            .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Pal.slab))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Pal.line, lineWidth: 1))
        }
    }

    private func button(_ icon: String, _ act: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { act() }
            Haptic.tick()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Pal.ink)
                .frame(width: 40, height: 42)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Field tanpa kotak — cuma garis bawah.
struct RuledField: View {
    var caption: String
    var placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(caption).stencil(9.5, tracking: 1.3).foregroundStyle(Pal.inkMuted)
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Pal.inkFaint))
                .font(.label(17, .semibold))
                .foregroundStyle(Pal.ink)
                .autocorrectionDisabled()
                .tint(Pal.volt)
            Rectangle().fill(Pal.line).frame(height: 1)
        }
    }
}
