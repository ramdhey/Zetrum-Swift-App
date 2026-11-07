import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: ParkingStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Pal.asphalt.ignoresSafeArea()

                if store.history.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "ticket")
                            .font(.system(size: 30, weight: .light))
                            .foregroundStyle(Pal.inkFaint)
                        Text("Belum ada karcis tersimpan")
                            .font(.label(14))
                            .foregroundStyle(Pal.inkMuted)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(store.history) { t in row(t) }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Riwayat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup") { dismiss() }.foregroundStyle(Pal.inkMuted)
                }
                ToolbarItem(placement: .primaryAction) {
                    if !store.history.isEmpty {
                        Button("Bersihkan") { store.clearHistory() }
                            .foregroundStyle(Pal.alarm)
                    }
                }
            }
            .toolbarBackground(Pal.asphalt, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private func row(_ t: ParkingTicket) -> some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(t.startedAt.formatted(.dateTime.day()))
                    .font(.meter(17, .bold)).foregroundStyle(Pal.ink)
                Text(t.startedAt.formatted(.dateTime.month(.abbreviated)))
                    .stencil(8, tracking: 1).foregroundStyle(Pal.inkFaint)
            }
            .frame(width: 42)

            Rectangle().fill(Pal.line).frame(width: 1, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(t.location.isEmpty ? "Tanpa lokasi" : t.location)
                    .font(.label(14, .semibold)).foregroundStyle(Pal.ink)
                    .lineLimit(1)
                Text("\(Durasi.humane(t.duration)) · \(Rupiah.full(t.ratePerHour))/jam")
                    .font(.label(11)).foregroundStyle(Pal.inkMuted)
            }

            Spacer(minLength: 6)

            Text(Rupiah.full(t.cost()))
                .font(.meter(15, .bold))
                .foregroundStyle(Pal.sodium)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Pal.asphaltSoft)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Pal.line, lineWidth: 1)
        )
    }
}
