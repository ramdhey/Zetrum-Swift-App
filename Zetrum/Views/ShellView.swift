import SwiftUI

enum Tab: String, CaseIterable, Identifiable {
    case home, history, stations, garage
    var id: String { rawValue }

    var label: String {
        switch self {
        case .home:     T("tab.home")
        case .history:  T("tab.history")
        case .stations: T("tab.stations")
        case .garage:   T("tab.garage")
        }
    }
    var symbol: String {
        switch self {
        case .home:     "bolt.horizontal.circle"
        case .history:  "list.bullet.rectangle"
        case .stations: "map"
        case .garage:   "car.2"
        }
    }
}

struct ShellView: View {
    @EnvironmentObject private var store: ChargeStore
    @State private var tab: Tab = .home
    @State private var showScan = false
    @State private var showCharging = false
    @State private var finished: ChargeSession?

    var body: some View {
        ZStack(alignment: .bottom) {
            DashBackground(warm: store.isFull ? Pal.ion : Pal.volt)

            Group {
                switch tab {
                case .home:     HomeScreen(onOpenMap: { tab = .stations },
                                           onOpenGarage: { tab = .garage },
                                           onOpenCharge: { showCharging = true })
                case .history:  HistoryScreen()
                case .stations: MapScreen()
                case .garage:   GarageScreen()
                }
            }
            .transition(.opacity)
            // ganti bahasa membangun ulang layarnya, bukan menambal teks
            // satu per satu — lebih murah daripada memastikan tiap anak
            // ikut mengamati pilihan bahasanya
            .id(store.lang)

            VStack(spacing: 0) {
                if store.active != nil && !showCharging {
                    LiveStrip { showCharging = true }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 9)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                TabBar(tab: $tab, onScan: { showScan = true })
            }
        }
        .animation(.easeInOut(duration: 0.22), value: tab)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: store.active?.id)
        .fullScreenCover(isPresented: $showScan) {
            ScanScreen()
        }
        .fullScreenCover(isPresented: $showCharging) {
            ChargingScreen(onClose: { showCharging = false },
                           onStop: {
                               showCharging = false
                               finished = store.stop()
                           })
        }
        .sheet(item: $store.pending) { p in
            ConfirmSheet(pending: p)
                .presentationDetents([.height(560)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Pal.void)
        }
        .sheet(item: $finished) { ReceiptSheet(session: $0) }
        .onChange(of: store.active?.id) { _, id in
            if id != nil { showScan = false; showCharging = true }
        }
        .onAppear { store.locator.ask() }
    }
}

// MARK: - Bar bawah

private struct TabBar: View {
    @Binding var tab: Tab
    var onScan: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            item(.home); item(.history)
            scanButton
            item(.stations); item(.garage)
        }
        .padding(.top, 9)
        .padding(.horizontal, 6)
        .background {
            Rectangle()
                .fill(Pal.void.opacity(0.92))
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) { Rectangle().fill(Pal.line).frame(height: 1) }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func item(_ t: Tab) -> some View {
        Button {
            Haptic.tick()
            tab = t
        } label: {
            VStack(spacing: 5) {
                Image(systemName: tab == t ? t.symbol + ".fill" : t.symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(height: 20)
                Text(t.label).font(.label(9.5, .semibold))
            }
            .foregroundStyle(tab == t ? Pal.volt : Pal.inkFaint)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Tombol pindai duduk lebih tinggi dari yang lain — ini aksi utamanya.
    private var scanButton: some View {
        Button {
            Haptic.thud()
            onScan()
        } label: {
            ZStack {
                Circle().fill(Pal.volt)
                    .shadow(color: Pal.volt.opacity(0.35), radius: 14, y: 5)
                Bolt().fill(Pal.void)
                    .frame(width: 17, height: 23)
            }
            .frame(width: 56, height: 56)
            .overlay(Circle().stroke(Pal.void, lineWidth: 4))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .offset(y: -16)
        .padding(.bottom, -16)
    }
}

// MARK: - Pengingat sesi berjalan

/// Selama mengisi, ini nempel di atas bar bawah di tab mana pun. Satu
/// ketukan untuk kembali ke layar pengisian.
private struct LiveStrip: View {
    @EnvironmentObject private var store: ChargeStore
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 11) {
                BoltMark(size: 30, tint: store.isFull ? Pal.ion : Pal.volt)
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.isFull ? T("strip.full") : T("strip.charging"))
                        .font(.label(12.5, .bold))
                        .foregroundStyle(store.isFull ? Pal.ion : Pal.volt)
                    Text(store.active?.place.name ?? "")
                        .font(.label(10.5))
                        .foregroundStyle(Pal.inkMuted)
                        .lineLimit(1)
                }
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Energi.persen(store.soc))%")
                        .font(.meter(15, .bold)).foregroundStyle(Pal.ink)
                    Text(Rupiah.full(store.cost))
                        .font(.label(10.5)).foregroundStyle(Pal.inkMuted)
                }
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Pal.inkFaint)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Pal.surface))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke((store.isFull ? Pal.ion : Pal.volt).opacity(0.35), lineWidth: 1))
            .shadow(color: .black.opacity(0.4), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
    }
}
