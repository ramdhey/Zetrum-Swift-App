import SwiftUI

struct ActiveChargeCard: View {
    @EnvironmentObject private var store: ChargeStore
    var onStop: () -> Void

    @State private var pulse = false

    private var done: Bool { store.isFull }
    private var accent: Color { done ? Pal.ion : Pal.volt }

    var body: some View {
        TicketCard(stroke: accent.opacity(done ? 0.45 : 0.16)) {
            VStack(spacing: 0) {
                panel
                Perforation(color: Pal.inkFaint.opacity(0.55)).padding(.horizontal, 14)
                tagihan
            }
        }
        .shadow(color: accent.opacity(done ? 0.2 : 0.09), radius: 30, y: 12)
        .shadow(color: .black.opacity(0.5), radius: 22, y: 14)
        .animation(.easeInOut(duration: 0.6), value: done)
    }

    // MARK: - Panel pengisian

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            stationBar.padding(.bottom, 22)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                UnitTag(text: Energi.persen(store.soc), unit: "%", size: 52, color: Pal.ink)
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("target").stencil(8.5, tracking: 1.2).foregroundStyle(Pal.inkFaint)
                    Text("\(Energi.persen(store.active?.targetSoC ?? 100))%")
                        .font(.meter(15, .bold))
                        .foregroundStyle(accent)
                }
            }
            .padding(.bottom, 14)

            BatteryPack(soc: store.soc,
                        target: store.active?.targetSoC ?? 100,
                        tint: accent,
                        charging: !done)

            HStack(spacing: 0) {
                metric("Masuk", "\(Energi.kwh(store.energy)) kWh")
                metric("Daya", done ? "0 kW" : "\(Energi.kw(store.power)) kW", align: .center)
                metric("Jalan", Durasi.clock(store.active?.elapsed(at: store.now) ?? 0),
                       align: .trailing)
            }
            .padding(.top, 20)

            countdown.padding(.top, 18)
        }
        .padding(22)
        .onAppear { pulse = true }
    }

    private var stationBar: some View {
        HStack(spacing: 10) {
            BoltMark(size: 30, tint: accent)
                .opacity(done ? 1 : (pulse ? 0.55 : 1))
                .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)

            VStack(alignment: .leading, spacing: 2) {
                Text(store.active?.station.name ?? "Zetrum")
                    .font(.label(14, .bold))
                    .foregroundStyle(Pal.ink)
                Text(store.active?.station.area ?? "")
                    .font(.label(10.5))
                    .foregroundStyle(Pal.inkMuted)
            }

            Spacer()

            Text(store.active?.station.powerLabel ?? "")
                .font(.meter(11, .bold))
                .foregroundStyle(Pal.inkMuted)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().stroke(Pal.line, lineWidth: 1))
        }
    }

    @ViewBuilder
    private var countdown: some View {
        if done {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 13, weight: .bold))
                Text("Sudah selesai — silakan dicabut")
                    .font(.label(12.5, .semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(Pal.ion)
            .padding(.vertical, 11).padding(.horizontal, 13)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Pal.ion.opacity(0.1))
            )
        } else if let sisa = store.remaining {
            HStack(spacing: 6) {
                Image(systemName: "hourglass")
                    .font(.system(size: 10, weight: .bold))
                Text("penuh dalam")
                    .font(.label(12))
                Text(Durasi.clock(sisa))
                    .font(.meter(12.5, .bold))
                    .contentTransition(.numericText(countsDown: true))
                Spacer(minLength: 0)
                if let f = store.finishAt {
                    Text("≈ \(f, format: .dateTime.hour().minute())")
                        .font(.meter(12))
                        .foregroundStyle(Pal.inkFaint)
                }
            }
            .foregroundStyle(Pal.ion)
        }
    }

    private func metric(_ caption: String, _ value: String,
                        align: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: align, spacing: 4) {
            Text(caption).stencil(8.5, tracking: 1.2).foregroundStyle(Pal.inkFaint)
            Text(value)
                .font(.meter(14, .bold))
                .foregroundStyle(Pal.ink)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity,
               alignment: align == .leading ? .leading : (align == .trailing ? .trailing : .center))
    }

    // MARK: - Sobekan bawah: yang harus dibayar

    private var tagihan: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    PriceTag(value: store.cost, size: 40, color: accent)
                        .shadow(color: accent.opacity(0.22), radius: 12)
                    Text("\(Rupiah.full(store.active?.station.ratePerKwh ?? 0)) per kWh")
                        .font(.label(11.5, .medium))
                        .foregroundStyle(Pal.inkFaint)
                }
                Spacer()
            }

            HoldToConfirm(title: "Tahan untuk cabut",
                          tint: done ? Pal.ion : Pal.alarm,
                          action: onStop)
        }
        .padding(22)
    }
}
