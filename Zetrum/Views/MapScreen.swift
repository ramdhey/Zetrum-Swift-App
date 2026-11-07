import SwiftUI

struct MapScreen: View {
    @EnvironmentObject private var store: ChargeStore
    @State private var search = ""
    @State private var onlyAvailable = false
    @State private var connector: Connector?
    @State private var venue: Venue?
    @State private var selectedID: String?
    @State private var detail: Place?
    @State private var recenter = 0
    @State private var expanded = false

    private var results: [Place] {
        store.nearby(onlyAvailable: onlyAvailable, connector: connector, search: search)
            .filter { venue == nil || $0.venue == venue }
    }

    private var selected: Place? { results.first { $0.id == selectedID } }

    var body: some View {
        ZStack(alignment: .top) {
            OSMMapView(places: results, style: store.tileStyle,
                       selectedID: $selectedID, recenterToken: recenter) { p in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    selectedID = p.id
                    expanded = false
                }
            }
            .ignoresSafeArea()

            topControls
            sideControls
            bottomPanel
            attribution
        }
        .sheet(item: $detail) { StationDetailScreen(place: $0) }
    }

    // MARK: Cari & saring

    private var topControls: some View {
        VStack(spacing: 9) {
            SearchField(placeholder: "Cari SPKLU, mal, stasiun…", text: $search)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    Chip(text: "Tersedia", symbol: "checkmark.circle.fill", on: onlyAvailable) {
                        onlyAvailable.toggle()
                    }
                    Chip(text: "Isi Cepat DC", symbol: "bolt.fill", on: connector == .ccs2) {
                        connector = connector == .ccs2 ? nil : .ccs2
                    }
                    Chip(text: "Motor", symbol: "scooter", on: connector == .shuko) {
                        connector = connector == .shuko ? nil : .shuko
                    }
                    Rectangle().fill(Pal.line).frame(width: 1, height: 20)
                    ForEach(Venue.allCases) { v in
                        Chip(text: v.label, symbol: v.symbol, on: venue == v, tint: Pal.ion) {
                            venue = venue == v ? nil : v
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background {
            LinearGradient(colors: [Pal.void, Pal.void.opacity(0.88), .clear],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        }
    }

    // MARK: Tombol di sisi kanan

    private var sideControls: some View {
        VStack(spacing: 9) {
            roundButton(store.tileStyle == .dark ? "sun.max.fill" : "moon.fill") {
                store.tileStyle = store.tileStyle == .dark ? .light : .dark
            }
            roundButton("location.fill") { recenter += 1 }
        }
        .padding(.trailing, 16)
        .padding(.top, 118)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private func roundButton(_ icon: String, _ act: @escaping () -> Void) -> some View {
        Button {
            Haptic.tick(); act()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Pal.ink)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Pal.surface.opacity(0.95)))
                .overlay(Circle().stroke(Pal.line, lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var attribution: some View {
        Text(store.tileStyle.attribution)
            .font(.system(size: 8.5, weight: .medium))
            .foregroundStyle(Pal.ink.opacity(0.55))
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(Capsule().fill(Pal.void.opacity(0.55)))
            .padding(.leading, 14)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.bottom, panelHeight + 74)
            .allowsHitTesting(false)
    }

    // MARK: Panel bawah

    private var panelHeight: CGFloat { expanded ? 420 : 236 }

    private var bottomPanel: some View {
        VStack(spacing: 0) {
            Capsule().fill(Pal.inkFaint).frame(width: 38, height: 4)
                .padding(.top, 8).padding(.bottom, 10)

            if let p = selected {
                PlacePreview(place: p, distance: store.distance(to: p),
                             onOpen: { detail = p },
                             onClose: { withAnimation { selectedID = nil } })
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                HStack {
                    Text("Stasiun Terdekat").font(.label(14.5, .bold)).foregroundStyle(Pal.ink)
                    Spacer()
                    Text("\(results.count) lokasi")
                        .font(.label(11)).foregroundStyle(Pal.inkMuted)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 9)

                ScrollView {
                    VStack(spacing: 9) {
                        ForEach(results) { p in
                            PlaceRow(place: p, distance: store.distance(to: p)) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    selectedID = p.id
                                }
                            }
                        }
                        if results.isEmpty {
                            Text("Tidak ada SPKLU yang cocok dengan saringan itu.")
                                .font(.label(12)).foregroundStyle(Pal.inkMuted)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 28)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(height: panelHeight)
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24, style: .continuous)
                .fill(Pal.void.opacity(0.97))
                .overlay(alignment: .top) {
                    UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24, style: .continuous)
                        .stroke(Pal.line, lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.5), radius: 18, y: -6)
        }
        .gesture(
            DragGesture(minimumDistance: 12)
                .onEnded { g in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                        if g.translation.height < -30 { expanded = true; selectedID = nil }
                        else if g.translation.height > 30 { expanded = false }
                    }
                }
        )
        .padding(.bottom, 74)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: selectedID)
    }
}

// MARK: - Kartu pratinjau penanda

private struct PlacePreview: View {
    let place: Place
    let distance: Double
    var onOpen: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Pal.volt.opacity(0.1))
                    Image(systemName: place.venue.symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Pal.volt)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 3) {
                    Text(place.name).font(.label(15, .bold)).foregroundStyle(Pal.ink)
                        .lineLimit(2)
                    Text(place.address).font(.label(10.5)).foregroundStyle(Pal.inkMuted)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Pal.inkFaint)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Pal.slab))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 7) {
                Chip(text: Jarak.near(distance), symbol: "location.fill", on: false)
                Chip(text: "★ \(Energi.kwh(place.rating, decimals: 1))", on: false)
                Chip(text: place.open24 ? "24 Jam" : place.hours, symbol: "clock", on: false)
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(place.available) dari \(place.totalUnits) konektor siap")
                        .font(.label(12, .semibold))
                        .foregroundStyle(place.available == 0 ? Pal.alarm : Pal.volt)
                    Text(place.tariffRange).font(.label(10.5)).foregroundStyle(Pal.inkMuted)
                }
                Spacer()
                Button(action: onOpen) {
                    HStack(spacing: 6) {
                        Text("Lihat Detail").font(.label(12.5, .bold))
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Pal.void)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Capsule().fill(Pal.volt))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Pal.surface))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Pal.line, lineWidth: 1))
    }
}
