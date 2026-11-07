import SwiftUI

/// Struk yang keluar setelah kabel dicabut. Kertas betulan — kontras dengan
/// panel yang gelap, jadi terasa seperti benda lain.
struct ReceiptSheet: View {
    let session: ChargeSession
    @Environment(\.dismiss) private var dismiss

    private var endedAt: Date { session.endedAt ?? Date() }
    private var soc: Double { session.soc(at: endedAt) }

    var body: some View {
        ZStack {
            Pal.void.ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer(minLength: 0)
                paper
                Button("Tutup") { dismiss() }
                    .font(.label(14, .semibold))
                    .foregroundStyle(Pal.inkMuted)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 26)
        }
        .presentationDetents([.large])
        .presentationBackground(Pal.void)
    }

    private var paper: some View {
        TicketCard(fill: Pal.receipt, stroke: .clear, corner: 10) {
            VStack(spacing: 0) {
                VStack(spacing: 14) {
                    HStack(spacing: 8) {
                        Bolt().fill(Pal.receiptInk).frame(width: 11, height: 15)
                        Text("Zetrum").stencil(11, tracking: 2.2)
                    }
                    .foregroundStyle(Pal.receiptInk.opacity(0.6))

                    PriceTag(value: session.cost(at: endedAt), size: 42, color: Pal.receiptInk)

                    Text("\(Energi.kwh(session.energy(at: endedAt))) kWh  ·  \(Durasi.humane(session.elapsed(at: endedAt)))")
                        .font(.label(13, .semibold))
                        .foregroundStyle(Pal.receiptInk.opacity(0.6))
                }
                .padding(.vertical, 26)

                Perforation(color: Pal.receiptInk.opacity(0.3)).padding(.horizontal, 16)

                VStack(spacing: 11) {
                    row("SPKLU", session.station.name)
                    row("Soket", "\(session.station.connector.label) · \(session.station.powerLabel)")
                    row("Mobil", session.carName.isEmpty ? "Mobil saya" : session.carName)
                    row("Baterai", "\(Energi.persen(session.startSoC))% → \(Energi.persen(soc))%")
                    row("Mulai", session.startedAt.formatted(date: .omitted, time: .shortened))
                    row("Selesai", endedAt.formatted(date: .omitted, time: .shortened))
                    row("Tarif", "\(Rupiah.full(session.station.ratePerKwh)) / kWh")
                }
                .padding(22)
            }
        }
        .shadow(color: .black.opacity(0.6), radius: 30, y: 16)
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(.label(12.5)).foregroundStyle(Pal.receiptInk.opacity(0.5))
            Spacer()
            Text(v).font(.meter(12.5, .semibold)).foregroundStyle(Pal.receiptInk)
        }
    }
}
