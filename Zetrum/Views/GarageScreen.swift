import SwiftUI

struct GarageScreen: View {
    @EnvironmentObject private var store: ChargeStore
    @State private var kind: VehicleKind = .car
    @State private var search = ""
    @State private var detail: Vehicle?

    private var groups: [(String, [Vehicle])] { Catalog.byBrand(kind, search: search) }
    private var count: Int { groups.reduce(0) { $0 + $1.1.count } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                mine
                picker
                SearchField(placeholder: "Cari merek atau model…", text: $search)

                if count == 0 {
                    Text("Tidak ada model yang cocok dengan “\(search)”.")
                        .font(.label(12.5)).foregroundStyle(Pal.inkMuted)
                        .padding(.vertical, 40)
                }

                ForEach(groups, id: \.0) { brand, list in
                    VStack(alignment: .leading, spacing: 9) {
                        SectionHead(title: brand, trailing: "\(list.count) model")
                        ForEach(list) { v in
                            VehicleRow(vehicle: v, selected: v.id == store.vehicleID) {
                                detail = v
                            }
                        }
                    }
                }

                Text("Spesifikasi diambil dari pabrikan dan media otomotif Indonesia. Kapasitas baterai memakai angka kotor; daya pengisian motor dihitung dari waktu pengisian yang diumumkan pabrikannya.")
                    .font(.label(10))
                    .foregroundStyle(Pal.inkFaint)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 118)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $detail) { VehicleDetailScreen(vehicle: $0) }
    }

    private var header: some View {
        HStack(spacing: 11) {
            BoltMark(size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text("Garasi").stencil(13, tracking: 2.6).foregroundStyle(Pal.ink)
                Text("\(Catalog.all.count) model EV di Indonesia")
                    .font(.label(11.5)).foregroundStyle(Pal.inkMuted)
            }
            Spacer()
        }
        .padding(.top, 10)
    }

    /// Kendaraan yang sedang dipakai, dengan nama panggilannya.
    private var mine: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Kendaraan Saya").stencil(9.5, tracking: 1.4).foregroundStyle(Pal.volt)
                Spacer()
                Image(systemName: "star.fill").font(.system(size: 10)).foregroundStyle(Pal.volt)
            }
            .padding(.horizontal, 15).padding(.top, 14)

            VehicleImage(vehicle: store.vehicle, height: 96)
                .padding(.vertical, 6)

            VStack(spacing: 12) {
                RuledField(caption: "Nama panggilan",
                           placeholder: store.vehicle.displayName,
                           text: $store.nickname)
                MetricStrip(items: [
                    .init(caption: "Baterai", value: Energi.kwh(store.vehicle.batteryKWh), unit: "kWh"),
                    .init(caption: "Jarak", value: "\(store.vehicle.rangeKm)", unit: "km"),
                    .init(caption: "Isi Cepat",
                          value: store.vehicle.dcMaxKW > 0 ? Daya.kw(store.vehicle.dcMaxKW) : "—",
                          unit: store.vehicle.dcMaxKW > 0 ? "kW" : nil,
                          tint: store.vehicle.dcMaxKW > 0 ? Pal.volt : Pal.inkFaint),
                ])
            }
            .padding(.horizontal, 15).padding(.bottom, 15)
        }
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Pal.surface))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(Pal.volt.opacity(0.3), lineWidth: 1))
    }

    private var picker: some View {
        HStack(spacing: 0) {
            ForEach(VehicleKind.allCases) { k in
                Button {
                    Haptic.tick()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) { kind = k }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: k.symbol).font(.system(size: 13, weight: .bold))
                        Text(k.plural).font(.label(13, .bold))
                        Text("\(Catalog.list(k).count)")
                            .font(.label(10.5, .bold))
                            .foregroundStyle(kind == k ? Pal.void.opacity(0.6) : Pal.inkFaint)
                    }
                    .foregroundStyle(kind == k ? Pal.void : Pal.inkMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(kind == k ? Pal.volt : .clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Pal.slab))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Pal.line, lineWidth: 1))
    }
}

// MARK: - Satu baris model

struct VehicleRow: View {
    let vehicle: Vehicle
    let selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VehicleImage(vehicle: vehicle, height: 44,
                             tint: selected ? Pal.volt : Pal.inkMuted)
                    .frame(width: 76)
                    .background(RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Pal.slab.opacity(0.6)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.model + (vehicle.variant.map { " " + $0 } ?? ""))
                        .font(.label(14, .bold)).foregroundStyle(Pal.ink)
                        .lineLimit(1).minimumScaleFactor(0.82)
                    HStack(spacing: 5) {
                        Text("\(Energi.kwh(vehicle.batteryKWh)) kWh")
                            .font(.label(10.5, .semibold)).foregroundStyle(Pal.volt)
                        Text("·").foregroundStyle(Pal.inkFaint)
                        Text("\(vehicle.rangeKm) km").font(.label(10.5)).foregroundStyle(Pal.inkMuted)
                        Text("·").foregroundStyle(Pal.inkFaint)
                        Text(vehicle.dcMaxKW > 0 ? "DC \(Daya.kw(vehicle.dcMaxKW)) kW" : "AC saja")
                            .font(.label(10.5))
                            .foregroundStyle(vehicle.dcMaxKW > 0 ? Pal.ion : Pal.inkFaint)
                    }
                }
                Spacer(minLength: 4)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 17)).foregroundStyle(Pal.volt)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold)).foregroundStyle(Pal.inkFaint)
                }
            }
            .padding(11)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(selected ? Pal.volt.opacity(0.08) : Pal.surface))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(selected ? Pal.volt.opacity(0.45) : Pal.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
