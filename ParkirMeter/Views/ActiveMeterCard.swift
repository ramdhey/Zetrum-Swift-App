import SwiftUI

struct ActiveMeterCard: View {
    @EnvironmentObject private var store: ParkingStore
    var onStop: () -> Void

    @State private var pulse = false

    private var warm: Bool { store.tickProgress > 0.88 && store.mode == .hourly }
    private var accent: Color { warm ? Pal.alarm : Pal.sodium }

    var body: some View {
        TicketCard(stroke: accent.opacity(warm ? 0.5 : 0.14)) {
            VStack(spacing: 0) {
                readout
                Perforation(color: Pal.inkFaint.opacity(0.55)).padding(.horizontal, 14)
                details
            }
        }
        .shadow(color: accent.opacity(warm ? 0.22 : 0.08), radius: 30, y: 12)
        .shadow(color: .black.opacity(0.5), radius: 22, y: 14)
        .animation(.easeInOut(duration: 0.6), value: warm)
    }

    // MARK: - Layar meteran

    private var readout: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)
                    .opacity(pulse ? 0.25 : 1)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
                Text("Sedang berjalan").stencil(9.5, tracking: 1.4).foregroundStyle(accent)
                Spacer()
                if let a = store.active {
                    Text("mulai \(a.startedAt, format: .dateTime.hour().minute())")
                        .font(.meter(11, .semibold))
                        .foregroundStyle(Pal.inkMuted)
                }
            }
            .padding(.bottom, 20)

            Text(Durasi.clock(store.elapsed))
                .font(.meter(52, .semibold))
                .foregroundStyle(Pal.ink)
                .contentTransition(.numericText())
                .animation(.linear(duration: 0.18), value: Int(store.elapsed))

            Text("durasi").stencil(9, tracking: 1.3).foregroundStyle(Pal.inkFaint)
                .padding(.top, 2)

            Divider().overlay(Pal.line).padding(.vertical, 18)

            PriceTag(value: store.currentCost, size: 46, color: accent)
                .shadow(color: accent.opacity(0.35), radius: 16)

            Text(store.mode == .hourly
                 ? "sudah masuk jam ke-\(Billing.blocksUsed(elapsed: store.elapsed))"
                 : "dihitung per menit")
                .stencil(9, tracking: 1.3)
                .foregroundStyle(Pal.inkFaint)
                .padding(.top, 4)

            if let next = store.nextTick {
                nextTickBar(next)
                    .padding(.top, 18)
            }
        }
        .padding(22)
        .onAppear { pulse = true }
    }

    private func nextTickBar(_ next: (at: Date, cost: Int)) -> some View {
        let remaining = max(0, next.at.timeIntervalSince(store.now))
        return VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 5) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .black))
                Text("naik ke \(Rupiah.full(next.cost)) dalam")
                    .font(.label(11.5, .medium))
                Text(Durasi.clock(remaining))
                    .font(.meter(11.5, .bold))
                    .contentTransition(.numericText(countsDown: true))
            }
            .foregroundStyle(warm ? Pal.alarm : Pal.inkMuted)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Pal.slab)
                    Capsule()
                        .fill(LinearGradient(colors: [accent.opacity(0.6), accent],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(4, geo.size.width * store.tickProgress))
                }
            }
            .frame(height: 5)
        }
        .animation(.linear(duration: 0.9), value: store.tickProgress)
    }

    // MARK: - Sobekan bawah

    private var details: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                meta("Lokasi", store.active?.location.isEmpty == false
                     ? store.active!.location : "—")
                Spacer(minLength: 10)
                meta("Plat", store.active?.plate.isEmpty == false
                     ? store.active!.plate : "—", align: .center)
                Spacer(minLength: 10)
                meta("Tarif", Rupiah.full(store.active?.ratePerHour ?? 0) + "/jam", align: .trailing)
            }

            HoldToConfirm(title: "Tahan untuk selesai", action: onStop)
        }
        .padding(22)
    }

    private func meta(_ caption: String, _ value: String,
                      align: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: align, spacing: 4) {
            Text(caption).stencil(8.5, tracking: 1.2).foregroundStyle(Pal.inkFaint)
            Text(value)
                .font(.label(13, .semibold))
                .foregroundStyle(Pal.ink)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity,
               alignment: align == .leading ? .leading : (align == .trailing ? .trailing : .center))
    }
}
