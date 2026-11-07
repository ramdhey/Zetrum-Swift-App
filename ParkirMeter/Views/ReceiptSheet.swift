import SwiftUI

/// Struk yang keluar saat meteran dimatikan. Kertas betulan — kontras
/// dengan layar meteran yang gelap, jadi terasa seperti benda lain.
struct ReceiptSheet: View {
    let ticket: ParkingTicket
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Pal.asphalt.ignoresSafeArea()
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
        .presentationBackground(Pal.asphalt)
    }

    private var paper: some View {
        TicketCard(fill: Pal.receipt, stroke: .clear, corner: 10) {
                VStack(spacing: 0) {
                VStack(spacing: 14) {
                    Text("Karcis Parkir").stencil(11, tracking: 2.2)
                        .foregroundStyle(Pal.receiptInk.opacity(0.55))

                    PriceTag(value: ticket.cost(), size: 44, color: Pal.receiptInk)

                    Text(Durasi.humane(ticket.duration))
                        .font(.label(14, .semibold))
                        .foregroundStyle(Pal.receiptInk.opacity(0.6))
                }
                .padding(.vertical, 28)

                Perforation(color: Pal.receiptInk.opacity(0.3)).padding(.horizontal, 16)

                VStack(spacing: 11) {
                    row("Masuk", ticket.startedAt.formatted(date: .omitted, time: .shortened))
                    row("Keluar", (ticket.endedAt ?? Date()).formatted(date: .omitted, time: .shortened))
                    row("Tarif", Rupiah.full(ticket.ratePerHour) + " / jam")
                    row("Hitungan", ticket.mode.title)
                    if !ticket.location.isEmpty { row("Lokasi", ticket.location) }
                    if !ticket.plate.isEmpty { row("Plat", ticket.plate) }
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
