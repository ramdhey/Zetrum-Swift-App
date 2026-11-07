import SwiftUI

// MARK: - Tombol

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
                .padding(.vertical, 18)
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
    var icon: String = "powerplug.portrait.slash"
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
                Image(systemName: holding ? "hand.tap.fill" : icon)
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

// MARK: - Isian

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

/// Angka yang diatur dengan tombol kurang/tambah.
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

/// Kotak cari dengan garis tipis, bukan kapsul abu-abu bawaan.
struct SearchField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Pal.inkMuted)
            TextField("", text: $text,
                      prompt: Text(placeholder).foregroundStyle(Pal.inkFaint))
                .font(.label(14.5))
                .foregroundStyle(Pal.ink)
                .autocorrectionDisabled()
                .tint(Pal.volt)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Pal.inkFaint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 13)
        .frame(height: 44)
        .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Pal.slab))
        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(Pal.line, lineWidth: 1))
    }
}

// MARK: - Serpihan kecil

/// Kapsul kecil untuk saringan dan penanda.
struct Chip: View {
    var text: String
    var symbol: String?
    var on: Bool = false
    var tint: Color = Pal.volt
    var action: (() -> Void)?

    var body: some View {
        let inner = HStack(spacing: 5) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: 10, weight: .bold))
            }
            Text(text).font(.label(12, .semibold))
        }
        .foregroundStyle(on ? Pal.void : Pal.inkMuted)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(Capsule().fill(on ? tint : Pal.slab))
        .overlay(Capsule().stroke(on ? .clear : Pal.line, lineWidth: 1))

        if let action {
            Button { Haptic.tick(); action() } label: { inner }.buttonStyle(.plain)
        } else {
            inner
        }
    }
}

/// Lencana keadaan kotak pengisian: titik + tulisan.
struct StatusTag: View {
    var status: UnitStatus
    var compact: Bool = false

    private var tint: Color {
        switch status {
        case .idle:   Pal.volt
        case .busy:   Pal.ion
        case .broken: Pal.alarm
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(tint).frame(width: 6, height: 6)
            Text(status.label)
                .font(.label(compact ? 10 : 11.5, .semibold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(tint.opacity(0.11)))
    }
}

/// Judul bagian dengan garis yang menyambung ke kanan.
struct SectionHead: View {
    var title: String
    var trailing: String?

    var body: some View {
        HStack(spacing: 10) {
            Text(title).stencil(10.5, tracking: 1.8).foregroundStyle(Pal.inkMuted)
            Rectangle().fill(Pal.line).frame(height: 1)
            if let trailing {
                Text(trailing).font(.label(11, .semibold)).foregroundStyle(Pal.inkFaint)
            }
        }
    }
}

/// Tiga angka berjajar dengan garis pemisah tegak.
struct MetricStrip: View {
    struct Item: Identifiable {
        var id = UUID()
        var caption: String
        var value: String
        var unit: String?
        var tint: Color = Pal.ink
    }
    var items: [Item]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                if i > 0 { Rectangle().fill(Pal.line).frame(width: 1, height: 30) }
                VStack(spacing: 5) {
                    Text(item.caption).stencil(8.5, tracking: 1.1).foregroundStyle(Pal.inkMuted)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(item.value).font(.meter(17, .bold)).foregroundStyle(item.tint)
                        if let u = item.unit {
                            Text(u).font(.label(10.5, .semibold)).foregroundStyle(Pal.inkFaint)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

/// Baris menu yang bisa ditekan, dengan panah di ujung.
struct ArrowRow<Leading: View>: View {
    var title: String
    var subtitle: String?
    @ViewBuilder var leading: Leading
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                leading
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.label(14.5, .semibold)).foregroundStyle(Pal.ink)
                    if let subtitle {
                        Text(subtitle).font(.label(11.5)).foregroundStyle(Pal.inkMuted)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Pal.inkFaint)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Pal.surface))
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(Pal.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Tombol kembali bergaya sendiri, karena bar bawaan terlalu terang.
struct BackButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.left")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Pal.ink)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Pal.void.opacity(0.75)))
                .overlay(Circle().stroke(Pal.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
