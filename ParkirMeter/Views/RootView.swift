import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: ParkingStore
    @State private var finished: ParkingTicket?
    @State private var showHistory = false

    var body: some View {
        ZStack {
            AsphaltBackground(warm: store.active == nil ? Pal.sodium : tint)

            ScrollView {
                VStack(spacing: 22) {
                    header

                    if store.active != nil {
                        ActiveMeterCard(onStop: { finished = store.stop() })
                            .transition(.asymmetric(
                                insertion: .push(from: .bottom).combined(with: .opacity),
                                removal: .scale(scale: 0.94).combined(with: .opacity)))
                    } else {
                        StartCard()
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
        .sheet(item: $finished) { ReceiptSheet(ticket: $0) }
        .sheet(isPresented: $showHistory) { HistoryView() }
    }

    private var tint: Color {
        guard store.active != nil else { return Pal.sodium }
        return store.tickProgress > 0.88 ? Pal.alarm : Pal.sodium
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Parkir Meter").stencil(12, tracking: 2.4).foregroundStyle(Pal.sodium)
                Text(store.active == nil ? "Meteran mati" : "Meteran jalan")
                    .font(.label(13, .medium))
                    .foregroundStyle(Pal.inkMuted)
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

    private var footer: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(store.active == nil ? Pal.inkFaint : Pal.mint)
                .frame(width: 6, height: 6)
            Text(store.active == nil
                 ? "Kartu di layar kunci muncul setelah kamu mulai"
                 : "Kartu di layar kunci sedang menghitung")
                .font(.label(11.5))
                .foregroundStyle(Pal.inkFaint)
        }
        .padding(.top, 2)
    }
}
