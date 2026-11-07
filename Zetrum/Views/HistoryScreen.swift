import SwiftUI

struct HistoryScreen: View {
    @EnvironmentObject private var store: ChargeStore
    @State private var receipt: ChargeSession?
    @State private var confirmClear = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                summary
                chart
                list
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 118)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $receipt) { ReceiptSheet(session: $0) }
        .confirmationDialog(T("history.clearTitle"), isPresented: $confirmClear,
                            titleVisibility: .visible) {
            Button(T("history.clearConfirm"), role: .destructive) { store.clearHistory() }
            Button(T("common.cancel"), role: .cancel) {}
        } message: {
            Text(T("history.clearBody"))
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            BoltMark(size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(T("history.title")).stencil(13, tracking: 2.6).foregroundStyle(Pal.ink)
                Text(TN("history.subtitle", store.history.count))
                    .font(.label(11.5)).foregroundStyle(Pal.inkMuted)
            }
            Spacer()
            if !store.history.isEmpty {
                Button { confirmClear = true } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Pal.inkMuted)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Pal.surface))
                        .overlay(Circle().stroke(Pal.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 10)
    }

    private var summary: some View {
        VStack(spacing: 13) {
            HStack {
                Text(T("history.energyUse")).stencil(10, tracking: 1.6).foregroundStyle(Pal.ink)
                Spacer()
                Text(Tanggal.month()).font(.label(11, .semibold)).foregroundStyle(Pal.inkMuted)
            }
            MetricStrip(items: [
                .init(caption: T("history.totalEnergy"), value: Energi.kwh(store.energyThisMonth), unit: "kWh"),
                .init(caption: T("history.spent"), value: Rupiah.plain(store.spentThisMonth), unit: "Rp",
                      tint: Pal.volt),
            ])
            Rectangle().fill(Pal.line).frame(height: 1)
            MetricStrip(items: [
                .init(caption: T("history.avgDuration"), value: Durasi.tight(avgDuration)),
                .init(caption: T("history.frequency"), value: "\(store.sessionsThisMonth)", unit: T("history.unitSession")),
                .init(caption: T("history.co2Saved"), value: Energi.kwh(store.co2SavedKg), unit: "kg",
                      tint: Pal.ion),
            ])
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Pal.surface))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Pal.line, lineWidth: 1))
    }

    private var avgDuration: TimeInterval {
        let cal = Calendar.current
        let month = store.history.filter {
            cal.isDate($0.endedAt ?? $0.startedAt, equalTo: Date(), toGranularity: .month)
        }
        guard !month.isEmpty else { return 0 }
        return month.reduce(0) { $0 + $1.elapsed() } / Double(month.count)
    }

    // MARK: Grafik enam bulan

    private var months: [(String, Double)] {
        let cal = Calendar.current
        return (0..<6).reversed().map { back in
            let date = cal.date(byAdding: .month, value: -back, to: Date()) ?? Date()
            let total = store.history
                .filter { cal.isDate($0.endedAt ?? $0.startedAt, equalTo: date, toGranularity: .month) }
                .reduce(0.0) { $0 + $1.energy() }
            return (Tanggal.shortMonth(date), total)
        }
    }

    private var chart: some View {
        let data = months
        let peak = max(data.map(\.1).max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 12) {
            SectionHead(title: T("history.monthly"), trailing: "kWh")
            if data.allSatisfy({ $0.1 == 0 }) {
                Text(T("history.noChart"))
                    .font(.label(12)).foregroundStyle(Pal.inkFaint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 42)
            } else {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(Array(data.enumerated()), id: \.offset) { i, m in
                        VStack(spacing: 7) {
                            Text(m.1 > 0 ? Energi.kwh(m.1, decimals: 0) : "")
                                .font(.meter(9.5, .bold)).foregroundStyle(Pal.inkMuted)
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(i == data.count - 1
                                      ? LinearGradient(colors: [Pal.volt, Pal.voltDeep],
                                                       startPoint: .top, endPoint: .bottom)
                                      : LinearGradient(colors: [Pal.slab, Pal.slab],
                                                       startPoint: .top, endPoint: .bottom))
                                .frame(height: max(4, 96 * m.1 / peak))
                            Text(m.0).stencil(8, tracking: 0.9).foregroundStyle(Pal.inkFaint)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 140, alignment: .bottom)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Pal.surface))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Pal.line, lineWidth: 1))
    }

    // MARK: Daftar sesi

    private var list: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHead(title: T("history.allSessions"))
            if store.history.isEmpty {
                VStack(spacing: 9) {
                    Image(systemName: "bolt.slash")
                        .font(.system(size: 26, weight: .light)).foregroundStyle(Pal.inkFaint)
                    Text(T("history.emptyTitle"))
                        .font(.label(13, .semibold)).foregroundStyle(Pal.inkMuted)
                    Text(T("history.emptyBody"))
                        .font(.label(11.5)).foregroundStyle(Pal.inkFaint)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 46)
            }
            ForEach(store.history) { s in
                Button { receipt = s } label: { row(s) }.buttonStyle(.plain)
            }
        }
    }

    private func row(_ s: ChargeSession) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Pal.volt.opacity(0.1))
                Image(systemName: s.place.venue.symbol)
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(Pal.volt)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(s.place.name).font(.label(13.5, .bold)).foregroundStyle(Pal.ink).lineLimit(1)
                Text("\(Tanggal.stamp(s.startedAt)) · \(Durasi.tight(s.elapsed())) · \(Energi.kwh(s.energy())) kWh")
                    .font(.label(10.5)).foregroundStyle(Pal.inkMuted)
                Text("\(Energi.persen(s.startSoC))% → \(Energi.persen(s.soc(at: s.endedAt ?? Date())))%  ·  \(s.vehicle.displayName)")
                    .font(.label(10)).foregroundStyle(Pal.inkFaint).lineLimit(1)
            }
            Spacer(minLength: 4)
            Text(Rupiah.full(s.cost()))
                .font(.meter(13.5, .bold)).foregroundStyle(Pal.ink)
        }
        .padding(11)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Pal.surface))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Pal.line, lineWidth: 1))
    }

}
