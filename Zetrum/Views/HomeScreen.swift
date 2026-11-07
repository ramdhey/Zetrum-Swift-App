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
                Text(store.active == nil ? "Siap mengisi" :
                        (store.isFull ? "Sudah penuh" : "Sedang mengisi"))
                    .font(.label(11.5))
                    .foregroundStyle(store.active == nil ? Pal.inkMuted
                                     : (store.isFull ? Pal.ion : Pal.volt))
            }
            Spacer()
            if store.active != nil {
                Button(action: onOpenCharge) {
                    HStack(spacing: 6) {
                        Text("Lihat").font(.label(12, .bold))
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
                        Text("Perkiraan Jarak").stencil(8.5, tracking: 1.1).foregroundStyle(Pal.inkMuted)
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
            Text("Baterai Sekarang").stencil(8.5, tracking: 1.1).foregroundStyle(Pal.inkMuted)
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
                Text("Konsumsi Bulan Ini").stencil(10, tracking: 1.6).foregroundStyle(Pal.ink)
                Spacer()
                Text(Self.monthName).font(.label(11, .semibold)).foregroundStyle(Pal.inkMuted)
            }
            MetricStrip(items: [
                .init(caption: "Listrik Masuk", value: Energi.kwh(store.energyThisMonth), unit: "kWh"),
                .init(caption: "Pengeluaran", value: Rupiah.plain(store.spentThisMonth), unit: "Rp",
                      tint: Pal.volt),
                .init(caption: "Sesi", value: "\(store.sessionsThisMonth)", unit: "×"),
            ])
            Rectangle().fill(Pal.line).frame(height: 1)
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 11, weight: .bold)).foregroundStyle(Pal.ion)
                Text("Emisi CO₂ yang tidak jadi keluar")
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

    private static let monthName: String = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "id_ID")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }()

    // MARK: Empat petak

    private var quickTiles: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("Butuh isi daya?").font(.label(16, .bold)).foregroundStyle(Pal.ink)
            HStack(spacing: 9) {
                tile(count: "\(Zetrum.places.filter(\.hasDC).count)", caption: "SPKLU DC",
                     symbol: "bolt.car.fill", tint: Pal.volt, action: onOpenMap)
                tile(count: "\(Zetrum.places.count)", caption: "Semua Lokasi",
                     symbol: "mappin.and.ellipse", tint: Pal.ion, action: onOpenMap)
                tile(count: "\(Zetrum.places.reduce(0) { $0 + $1.available })", caption: "Konektor Siap",
                     symbol: "powerplug.portrait.fill", tint: Pal.volt, action: onOpenMap)
                tile(count: "\(Catalog.all.count)", caption: "Model EV",
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
                Text("SPKLU Terdekat").font(.label(16, .bold)).foregroundStyle(Pal.ink)
                Spacer()
                Button(action: onOpenMap) {
                    HStack(spacing: 4) {
                        Text("Lihat peta").font(.label(12, .semibold))
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
            SectionHead(title: "Pengisian di rumah")
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
                        Text("ke \(Energi.persen(store.targetSoC))%")
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
        Text("Lokasi SPKLU di aplikasi ini contoh, bukan data operasional PLN.")
            .font(.label(10))
            .foregroundStyle(Pal.inkFaint)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
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
                        Text(place.open24 ? "24 Jam" : place.hours)
                            .font(.label(10)).foregroundStyle(Pal.inkFaint)
                    }
                    HStack(spacing: 5) {
                        Text("\(place.available)/\(place.totalUnits) konektor")
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
