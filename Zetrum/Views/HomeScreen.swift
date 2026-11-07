import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject private var store: ChargeStore
    var onOpenMap: () -> Void
    var onOpenGarage: () -> Void
    var onOpenCharge: () -> Void

    @State private var detail: Place?

    private var nearest: [Place] { Array(store.nearby().prefix(3)) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                vehicleCard
                monthCard
                quickTiles
                nearbyBlock
                homeCharging
                attribution
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 118)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $detail) { StationDetailScreen(place: $0) }
    }

    // MARK: Kepala

    private var header: some View {
        HStack(spacing: 11) {
            BoltMark(size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text("Zetrum").stencil(13, tracking: 2.6).foregroundStyle(Pal.ink)
                Text(store.active == nil ? T("app.ready") :
                        (store.isFull ? T("app.full") : T("app.charging")))
                    .font(.label(11.5))
                    .foregroundStyle(store.active == nil ? Pal.inkMuted
                                     : (store.isFull ? Pal.ion : Pal.volt))
            }
            Spacer(minLength: 6)
            LangPill(lang: $store.lang)
            if store.active != nil {
                Button(action: onOpenCharge) {
                    HStack(spacing: 6) {
                        Text(T("common.view")).font(.label(12, .bold))
                        Image(systemName: "arrow.up.right").font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Pal.void)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Capsule().fill(store.isFull ? Pal.ion : Pal.volt))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 10)
    }

    // MARK: Kartu kendaraan

    private var vehicleCard: some View {
        Button(action: onOpenGarage) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(store.vehicleLabel)
                            .font(.label(21, .bold))
                            .foregroundStyle(Pal.ink)
                            .lineLimit(1).minimumScaleFactor(0.7)
                        Text(store.nickname.isEmpty
                             ? "\(store.vehicle.kind.label) · \(store.vehicle.style.label) · \(store.vehicle.ports.map(\.label).joined(separator: " / "))"
                             : store.vehicle.displayName)
                            .font(.label(11.5))
                            .foregroundStyle(Pal.inkMuted)
                            .lineLimit(1).minimumScaleFactor(0.8)
                        HStack(spacing: 7) {
                            Chip(text: Energi.kwh(store.vehicle.batteryKWh) + " kWh",
                                 symbol: "bolt.batteryblock.fill")
                            Chip(text: "\(store.vehicle.rangeKm) km", symbol: "road.lanes")
                        }
                        .padding(.top, 3)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Pal.inkFaint)
                        .padding(.top, 6)
                }
                .padding(.horizontal, 17)
                .padding(.top, 17)

                VehicleImage(vehicle: store.vehicle, height: 104)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)

                Rectangle().fill(Pal.line).frame(height: 1)

                HStack(spacing: 0) {
                    socBlock
                    Rectangle().fill(Pal.line).frame(width: 1, height: 36)
                    VStack(spacing: 4) {
                        Text(T("home.estRange")).stencil(8.5, tracking: 1.1).foregroundStyle(Pal.inkMuted)
                        Text("\(Int((store.soc / 100 * Double(store.vehicle.rangeKm)).rounded())) km")
                            .font(.meter(17, .bold)).foregroundStyle(Pal.ink)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 13)
            }
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Pal.surface))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Pal.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var socBlock: some View {
        VStack(spacing: 6) {
            Text(T("home.batteryNow")).stencil(8.5, tracking: 1.1).foregroundStyle(Pal.inkMuted)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Energi.persen(store.soc))")
                    .font(.meter(17, .bold))
                    .foregroundStyle(store.active != nil ? Pal.volt : Pal.ink)
                Text("%").font(.label(11, .semibold)).foregroundStyle(Pal.inkFaint)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Konsumsi bulan ini

    private var monthCard: some View {
        VStack(spacing: 13) {
            HStack {
                Text(T("home.monthTitle")).stencil(10, tracking: 1.6).foregroundStyle(Pal.ink)
                Spacer()
                Text(Tanggal.month()).font(.label(11, .semibold)).foregroundStyle(Pal.inkMuted)
            }
            MetricStrip(items: [
                .init(caption: T("home.energyIn"), value: Energi.kwh(store.energyThisMonth), unit: "kWh"),
                .init(caption: T("home.spent"), value: Rupiah.plain(store.spentThisMonth), prefix: "Rp",
                      tint: Pal.volt),
                .init(caption: T("home.sessions"), value: "\(store.sessionsThisMonth)", unit: "×"),
            ])
            Rectangle().fill(Pal.line).frame(height: 1)
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 11, weight: .bold)).foregroundStyle(Pal.ion)
                Text(T("home.co2"))
                    .font(.label(11.5)).foregroundStyle(Pal.inkMuted)
                Spacer()
                Text(Energi.kwh(store.co2SavedKg) + " kg")
                    .font(.meter(13, .bold)).foregroundStyle(Pal.ion)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Pal.surface))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Pal.line, lineWidth: 1))
    }

    // MARK: Empat petak

    private var quickTiles: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(T("home.needCharge")).font(.label(16, .bold)).foregroundStyle(Pal.ink)
            HStack(spacing: 9) {
                tile(count: "\(Zetrum.places.filter(\.hasDC).count)", caption: T("home.tileDC"),
                     symbol: "bolt.car.fill", tint: Pal.volt, action: onOpenMap)
                tile(count: "\(Zetrum.places.count)", caption: T("home.tileAll"),
                     symbol: "mappin.and.ellipse", tint: Pal.ion, action: onOpenMap)
                tile(count: "\(Zetrum.places.reduce(0) { $0 + $1.available })", caption: T("home.tileFree"),
                     symbol: "powerplug.portrait.fill", tint: Pal.volt, action: onOpenMap)
                tile(count: "\(Catalog.all.count)", caption: T("home.tileModels"),
                     symbol: "car.2.fill", tint: Pal.ion, action: onOpenGarage)
            }
        }
    }

    private func tile(count: String, caption: String, symbol: String,
                      tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(height: 20)
                Text(count).font(.meter(15, .bold)).foregroundStyle(Pal.ink)
                Text(caption)
                    .font(.label(9, .medium)).foregroundStyle(Pal.inkMuted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2).minimumScaleFactor(0.8)
                    .frame(height: 24, alignment: .top)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Pal.surface))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Pal.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: Terdekat

    private var nearbyBlock: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text(T("home.nearest")).font(.label(16, .bold)).foregroundStyle(Pal.ink)
                Spacer()
                Button(action: onOpenMap) {
                    HStack(spacing: 4) {
                        Text(T("home.viewMap")).font(.label(12, .semibold))
                        Image(systemName: "chevron.right").font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(Pal.volt)
                }
                .buttonStyle(.plain)
            }
            ForEach(nearest) { p in
                PlaceRow(place: p, distance: store.distance(to: p)) { detail = p }
            }
        }
    }

    // MARK: Pengisian rumah

    private var homeCharging: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHead(title: T("home.homeCharging"))
            if let home = Zetrum.place("home"), let unit = home.units.first {
                let est = store.estimate(for: unit)
                HStack(spacing: 13) {
                    SocketGlyph(kind: unit.connector.glyph, size: 30, tint: Pal.ion)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(Pal.ion.opacity(0.1)))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(unit.title).font(.label(14, .bold)).foregroundStyle(Pal.ink)
                        Text("\(unit.headline)  ·  \(Rupiah.decimal(unit.ratePerKwh))/kWh")
                            .font(.label(10.5)).foregroundStyle(Pal.inkMuted)
                    }
                    Spacer(minLength: 6)
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(est.duration.map(Durasi.tight) ?? "—")
                            .font(.meter(14, .bold)).foregroundStyle(Pal.ink)
                        Text(T("home.toPercent", Energi.persen(store.targetSoC)))
                            .font(.label(10)).foregroundStyle(Pal.inkFaint)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 17, style: .continuous).fill(Pal.surface))
                .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Pal.line, lineWidth: 1))
                .onTapGesture { detail = home }
            }
        }
    }

    private var attribution: some View {
        Text(T("home.disclaimer"))
            .font(.label(10))
            .foregroundStyle(Pal.inkFaint)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }
}

// MARK: - Pil pilihan

/// Dua segmen dengan penanda yang menggeser di belakangnya. Ditaruh di
/// layar pertama karena kalau disembunyikan di pengaturan, orang harus
/// mencari dulu.
private struct SegPill<Item: Identifiable & Equatable>: View {
    var items: [Item]
    @Binding var selection: Item
    var title: (Item) -> String
    var caption: (Item) -> String
    var width: CGFloat
    var tint: Color = Pal.volt
    @Namespace private var slot

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                let on = selection == item
                Text(title(item))
                    .font(.label(10.5, .bold))
                    .foregroundStyle(on ? Pal.void : Pal.inkMuted)
                    .frame(width: width, height: 23)
                    .background {
                        if on {
                            Capsule().fill(tint)
                                .matchedGeometryEffect(id: "slot", in: slot)
                        }
                    }
                    .contentShape(Capsule())
                    .onTapGesture {
                        guard !on else { return }
                        Haptic.tick()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            selection = item
                        }
                    }
                    .accessibilityLabel(caption(item))
            }
        }
        .padding(2)
        .background(Capsule().fill(Pal.slab))
        .overlay(Capsule().stroke(Pal.line, lineWidth: 1))
    }
}

private struct LangPill: View {
    @Binding var lang: Lang
    var body: some View {
        SegPill(items: Lang.allCases, selection: $lang,
                title: { $0.short }, caption: { $0.label }, width: 27)
    }
}

// MARK: - Baris satu SPKLU

struct PlaceRow: View {
    let place: Place
    var distance: Double?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(place.available == 0 ? Pal.alarm.opacity(0.1) : Pal.volt.opacity(0.1))
                    Image(systemName: place.venue.symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(place.available == 0 ? Pal.alarm : Pal.volt)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.label(14, .bold)).foregroundStyle(Pal.ink)
                        .lineLimit(1).minimumScaleFactor(0.85)
                    HStack(spacing: 6) {
                        Text(place.venue.label)
                            .font(.label(10)).foregroundStyle(Pal.inkFaint)
                        if let d = distance {
                            Text("·").foregroundStyle(Pal.inkFaint)
                            Text(Jarak.near(d)).font(.label(10)).foregroundStyle(Pal.inkFaint)
                        }
                        Text("·").foregroundStyle(Pal.inkFaint)
                        Text(place.hoursLabel)
                            .font(.label(10)).foregroundStyle(Pal.inkFaint)
                    }
                    HStack(spacing: 5) {
                        Text(T("place.connectors", place.available, place.totalUnits))
                            .font(.label(10.5, .semibold))
                            .foregroundStyle(place.available == 0 ? Pal.alarm : Pal.volt)
                        if place.hasDC {
                            Text("DC \(Daya.kw(place.peakKW)) kW")
                                .font(.label(10, .semibold))
                                .foregroundStyle(Pal.ion)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(Pal.ion.opacity(0.12)))
                        }
                    }
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold)).foregroundStyle(Pal.inkFaint)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 17, style: .continuous).fill(Pal.surface))
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Pal.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
