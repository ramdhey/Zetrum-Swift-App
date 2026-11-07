import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: ChargeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Pal.void.ignoresSafeArea()

                if store.history.isEmpty {
                    VStack(spacing: 10) {
                        Bolt().fill(Pal.inkFaint).frame(width: 22, height: 30)
                        Text("Belum ada pengisian tersimpan")
                            .font(.label(14))
                            .foregroundStyle(Pal.inkMuted)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(store.history) { s in row(s) }
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
            .toolbarBackground(Pal.void, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private func row(_ s: ChargeSession) -> some View {
        let end = s.endedAt ?? Date()
        return HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(s.startedAt.formatted(.dateTime.day()))
                    .font(.meter(17, .bold)).foregroundStyle(Pal.ink)
                Text(s.startedAt.formatted(.dateTime.month(.abbreviated)))
                    .stencil(8, tracking: 1).foregroundStyle(Pal.inkFaint)
            }
            .frame(width: 42)

            Rectangle().fill(Pal.line).frame(width: 1, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(s.station.name)
                    .font(.label(14, .semibold)).foregroundStyle(Pal.ink)
                    .lineLimit(1)
                Text("\(Energi.persen(s.startSoC))% → \(Energi.persen(s.soc(at: end)))%  ·  \(Energi.kwh(s.energy(at: end))) kWh")
                    .font(.label(11)).foregroundStyle(Pal.inkMuted)
            }

            Spacer(minLength: 6)

            Text(Rupiah.full(s.cost(at: end)))
                .font(.meter(15, .bold))
                .foregroundStyle(Pal.volt)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Pal.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Pal.line, lineWidth: 1)
        )
    }
}
