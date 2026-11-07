import SwiftUI

struct SetupCard: View {
    @EnvironmentObject private var store: ChargeStore

    var body: some View {
        TicketCard {
            VStack(spacing: 0) {
                mobil
                Perforation(color: Pal.inkFaint.opacity(0.55)).padding(.horizontal, 14)
                stasiun
            }
        }
        .shadow(color: .black.opacity(0.5), radius: 26, y: 14)
    }

    // ——— Keadaan mobil. Tiap kali colok, isinya beda, jadi ini yang diatur dulu.

    private var mobil: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Keadaan mobil").stencil(9.5, tracking: 1.4).foregroundStyle(Pal.inkMuted)
                    Text("Sekarang di berapa,\nmau diisi sampai berapa?")
                        .font(.label(22, .semibold))
                        .foregroundStyle(Pal.ink)
                        .lineSpacing(2)
                }
                Spacer()
            }

            RuledField(caption: "Mobil", placeholder: "Mobil saya", text: $store.carName)

            NudgeRow(caption: "Kapasitas baterai",
                     text: "\(Energi.kwh(store.capacityKWh)) kWh",
                     onMinus: { store.capacityKWh = max(10, store.capacityKWh - 0.5) },
                     onPlus:  { store.capacityKWh = min(200, store.capacityKWh + 0.5) })

            socRow(caption: "Baterai sekarang",
                   value: store.soc,
                   tint: Pal.inkMuted,
                   binding: Binding(get: { store.startSoC },
                                    set: { store.startSoC = min($0, store.targetSoC - 1) }),
                   lower: 0)

            socRow(caption: "Isi sampai",
                   value: store.targetSoC,
                   tint: Pal.volt,
                   binding: Binding(get: { store.targetSoC },
                                    set: { store.targetSoC = max($0, store.startSoC + 1) }),
                   lower: store.startSoC,
                   presets: [80, 90, 100])
        }
        .padding(22)
    }

    private func socRow(caption: String, value: Double, tint: Color,
                        binding: Binding<Double>, lower: Double,
                        presets: [Double] = []) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(caption).stencil(9.5, tracking: 1.3).foregroundStyle(Pal.inkMuted)
                Spacer()
                Text("\(Energi.persen(binding.wrappedValue))%")
                    .font(.meter(17, .bold))
                    .foregroundStyle(tint == Pal.volt ? Pal.volt : Pal.ink)
                    .contentTransition(.numericText())
            }

            if !presets.isEmpty {
                HStack(spacing: 7) {
                    ForEach(presets, id: \.self) { p in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                                binding.wrappedValue = p
                            }
                            Haptic.tick()
                        } label: {
                            Text("\(Int(p))%")
                                .font(.label(11.5, .bold))
                                .foregroundStyle(binding.wrappedValue == p ? Pal.void : Pal.inkMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(binding.wrappedValue == p ? Pal.volt : Pal.slab)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: 210)
            }

            SocSlider(value: binding, tint: tint == Pal.volt ? Pal.volt : Pal.inkMuted,
                      lowerBound: lower)
        }
    }

    // ——— SPKLU dan perkiraan

    private var stasiun: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pilih SPKLU").stencil(9.5, tracking: 1.3).foregroundStyle(Pal.inkMuted)

            VStack(spacing: 8) {
                ForEach(Station.all) { s in
                    StationRow(station: s, selected: store.stationID == s.id) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                            store.stationID = s.id
                        }
                        Haptic.tick()
                    }
                }
            }

            estimasi

            SlabButton(enabled: store.targetSoC > store.startSoC) {
                store.start()
            } label: {
                HStack(spacing: 10) {
                    Bolt().fill(Pal.void).frame(width: 11, height: 15)
                    Text("Mulai Mengisi").stencil(13, tracking: 1.6)
                }
                .foregroundStyle(Pal.void)
            }
        }
        .padding(22)
    }

    private var estimasi: some View {
        HStack(spacing: 0) {
            cell("Perkiraan", store.draftDuration.map { Durasi.humane($0) } ?? "tak tercapai")
            Rectangle().fill(Pal.line).frame(width: 1, height: 30)
            cell("Masuk", "\(Energi.kwh(store.draftEnergy)) kWh", align: .center)
            Rectangle().fill(Pal.line).frame(width: 1, height: 30)
            cell("Bayar", Rupiah.full(store.draftCost), align: .trailing, tint: Pal.volt)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Pal.void.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Pal.line, lineWidth: 1)
        )
    }

    private func cell(_ caption: String, _ value: String,
                      align: HorizontalAlignment = .leading,
                      tint: Color = Pal.ink) -> some View {
        VStack(alignment: align, spacing: 4) {
            Text(caption).stencil(8.5, tracking: 1.2).foregroundStyle(Pal.inkFaint)
            Text(value)
                .font(.meter(13.5, .bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity,
               alignment: align == .leading ? .leading : (align == .trailing ? .trailing : .center))
    }
}
