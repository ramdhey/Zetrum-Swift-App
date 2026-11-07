import SwiftUI

struct StartCard: View {
    @EnvironmentObject private var store: ParkingStore
    @FocusState private var focus: Field?
    private enum Field { case lokasi, plat }

    private let presets = [2_000, 3_000, 5_000, 10_000]

    var body: some View {
        TicketCard {
                VStack(spacing: 0) {
                // ——— kepala karcis
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Karcis baru").stencil(9.5, tracking: 1.4).foregroundStyle(Pal.inkMuted)
                            Text("Isi dulu, lalu jalankan\nmeterannya.")
                                .font(.label(23, .semibold))
                                .foregroundStyle(Pal.ink)
                                .lineSpacing(2)
                        }
                        Spacer()
                        Image(systemName: "parkingsign")
                            .font(.system(size: 26, weight: .black))
                            .foregroundStyle(Pal.sodium)
                            .padding(11)
                            .background(Circle().fill(Pal.sodium.opacity(0.12)))
                    }

                    HStack(alignment: .bottom, spacing: 18) {
                        RuledField(caption: "Lokasi", placeholder: "Basement B2",
                                   text: $store.location)
                            .focused($focus, equals: .lokasi)
                        RuledField(caption: "Plat", placeholder: "B 1234 ABC",
                                   text: $store.plate, uppercase: true, width: 124)
                            .focused($focus, equals: .plat)
                    }
                }
                .padding(22)

                Perforation(color: Pal.inkFaint.opacity(0.55))
                    .padding(.horizontal, 14)

                // ——— badan karcis
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 11) {
                        Text("Tarif per jam").stencil(9.5, tracking: 1.3).foregroundStyle(Pal.inkMuted)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 9) {
                                ForEach(presets, id: \.self) { v in
                                    RateChip(value: v, selected: store.ratePerHour == v) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                            store.ratePerHour = v
                                        }
                                        Haptic.tick()
                                    }
                                }
                                stepper
                            }
                            .padding(.vertical, 2)
                        }
                        .scrollClipDisabled()
                    }

                    VStack(alignment: .leading, spacing: 11) {
                        Text("Cara hitung").stencil(9.5, tracking: 1.3).foregroundStyle(Pal.inkMuted)
                        HStack(spacing: 9) {
                            ForEach(BillingMode.allCases) { m in
                                modeCard(m)
                            }
                        }
                    }

                    SlabButton {
                        focus = nil
                        store.start()
                    } label: {
                        HStack(spacing: 10) {
                            Text("Jalankan Meteran").stencil(13, tracking: 1.6)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .heavy))
                        }
                        .foregroundStyle(Pal.asphalt)
                    }
                    .padding(.top, 2)
                }
                .padding(22)
            }
        }
        .shadow(color: .black.opacity(0.5), radius: 26, y: 14)
    }

    private var stepper: some View {
        HStack(spacing: 0) {
            stepButton("minus") {
                store.ratePerHour = max(500, store.ratePerHour - 500)
            }
            Divider().frame(height: 22).overlay(Pal.line)
            stepButton("plus") {
                store.ratePerHour = min(200_000, store.ratePerHour + 500)
            }
        }
        .frame(height: 54)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Pal.slab)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(Pal.line, lineWidth: 1)
        )
    }

    private func stepButton(_ icon: String, _ act: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { act() }
            Haptic.tick()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Pal.ink)
                .frame(width: 42, height: 54)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func modeCard(_ m: BillingMode) -> some View {
        let on = store.mode == m
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) { store.mode = m }
            Haptic.tick()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(m.title)
                    .font(.label(14, .bold))
                    .foregroundStyle(on ? Pal.sodium : Pal.ink)
                Text(m.blurb)
                    .font(.label(10.5))
                    .foregroundStyle(on ? Pal.ink.opacity(0.75) : Pal.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 13)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(on ? Pal.sodium.opacity(0.12) : Pal.slab)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(on ? Pal.sodium.opacity(0.55) : Pal.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
