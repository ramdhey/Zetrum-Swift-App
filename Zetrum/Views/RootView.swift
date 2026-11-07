import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: ChargeStore
    @State private var finished: ChargeSession?
    @State private var showHistory = false

    var body: some View {
        ZStack {
            DashBackground(warm: store.isFull ? Pal.ion : Pal.volt)

            ScrollView {
                VStack(spacing: 22) {
                    header

                    if store.active != nil {
                        ActiveChargeCard(onStop: { finished = store.stop() })
                            .transition(.asymmetric(
                                insertion: .push(from: .bottom).combined(with: .opacity),
                                removal: .scale(scale: 0.94).combined(with: .opacity)))
                    } else {
                        SetupCard()
                            .transition(.asymmetric(
                                insertion: .push(from: .top).combined(with: .opacity),
                                removal: .scale(scale: 0.94).combined(with: .opacity)))
                    }

                    footer
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: store.active?.id)
        .animation(.easeInOut(duration: 0.7), value: store.isFull)
        .sheet(item: $finished) { ReceiptSheet(session: $0) }
        .sheet(isPresented: $showHistory) { HistoryView() }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 11) {
            BoltMark(size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text("Zetrum").stencil(13, tracking: 2.6).foregroundStyle(Pal.ink)
                Text(status)
                    .font(.label(12, .medium))
                    .foregroundStyle(store.isFull ? Pal.ion : Pal.inkMuted)
            }
            Spacer()
            Button { showHistory = true } label: {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Hari ini").stencil(8.5, tracking: 1.2).foregroundStyle(Pal.inkMuted)
                    Text(Rupiah.full(store.spentToday))
                        .font(.meter(15, .bold))
                        .foregroundStyle(Pal.ink)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 14)
    }

    private var status: String {
        guard store.active != nil else { return "Belum tersambung" }
        return store.isFull ? "Sudah selesai, boleh dicabut" : "Sedang mengisi"
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(store.active == nil ? Pal.inkFaint : (store.isFull ? Pal.ion : Pal.volt))
                .frame(width: 6, height: 6)
            Text(footerText)
                .font(.label(11.5))
                .foregroundStyle(Pal.inkFaint)
        }
        .padding(.top, 2)
    }

    private var footerText: String {
        guard store.active != nil else {
            return "Kartu di layar kunci muncul setelah pengisian dimulai"
        }
        return store.isFull
            ? "Kabar sudah dikirim — mobil boleh dijemput"
            : "Boleh ditinggal, kartunya terus menghitung di layar kunci"
    }
}
