import SwiftUI

struct VehicleDetailScreen: View {
    let vehicle: Vehicle
    @EnvironmentObject private var store: ChargeStore
    @Environment(\.dismiss) private var dismiss

    /// Daya kotak pengisian yang betul-betul ada di jaringan Zetrum.
    private var rungs: [Double] {
        vehicle.kind == .bike ? [2.2] : [7.4, 11, 22, 50, 60, 120, 200]
    }

    var body: some View {
        ZStack(alignment: .top) {
            Pal.void.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    specs
                    ports
                    chargeTable
                    picker
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)

            HStack {
                BackButton { dismiss() }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 8)
        }
        .presentationBackground(Pal.void)
    }

    private var hero: some View {
        VStack(spacing: 13) {
            ZStack {
                RadialGradient(colors: [Pal.volt.opacity(0.14), .clear],
                               center: .center, startRadius: 4, endRadius: 190)
                VehicleImage(vehicle: vehicle, height: 132)
            }
            .frame(height: 190)

            VStack(spacing: 5) {
                Text(vehicle.brand).stencil(10.5, tracking: 2.2).foregroundStyle(Pal.volt)
                Text(vehicle.model).font(.label(25, .bold)).foregroundStyle(Pal.ink)
                if let v = vehicle.variant {
                    Text(v).font(.label(12.5)).foregroundStyle(Pal.inkMuted)
                }
            }

            HStack(spacing: 7) {
                Chip(text: vehicle.kind.label, symbol: vehicle.kind.symbol)
                Chip(text: vehicle.style.label)
                if vehicle.dcMaxKW > 0 {
                    Chip(text: "Isi Cepat DC", symbol: "bolt.fill", on: true)
                }
            }
        }
        .padding(.top, 12)
    }

    private var specs: some View {
        VStack(spacing: 12) {
            MetricStrip(items: [
                .init(caption: "Baterai", value: Energi.kwh(vehicle.batteryKWh), unit: "kWh",
                      tint: Pal.volt),
                .init(caption: "Jarak Klaim", value: "\(vehicle.rangeKm)", unit: "km"),
                .init(caption: "Efisiensi", value: Energi.kwh(vehicle.kmPerKwh), unit: "km/kWh",
                      tint: Pal.ion),
            ])
            Rectangle().fill(Pal.line).frame(height: 1)
            MetricStrip(items: [
                .init(caption: "AC Maks", value: Daya.kw(vehicle.acMaxKW), unit: "kW"),
                .init(caption: "DC Maks",
                      value: vehicle.dcMaxKW > 0 ? Daya.kw(vehicle.dcMaxKW) : "—",
                      unit: vehicle.dcMaxKW > 0 ? "kW" : nil,
                      tint: vehicle.dcMaxKW > 0 ? Pal.volt : Pal.inkFaint),
                .init(caption: "Isi 0–100%",
                      value: Durasi.tight(fullTime), unit: nil),
            ])
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Pal.surface))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Pal.line, lineWidth: 1))
    }

    private var fullTime: TimeInterval {
        let kw = vehicle.dcMaxKW > 0 ? min(vehicle.dcMaxKW, 150) : vehicle.acMaxKW
        let plan = Charge.Plan(capacityKWh: vehicle.batteryKWh, startSoC: 0, targetSoC: 100,
                               ratedKW: kw, taperFloor: vehicle.dcMaxKW > 0 ? 0.18 : 0.6,
                               ratePerKwh: 0, serviceFee: 0)
        return Charge.time(plan, toReach: 100) ?? 0
    }

    private var ports: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHead(title: "Soket")
            HStack(spacing: 10) {
                ForEach(vehicle.ports) { c in
                    HStack(spacing: 10) {
                        SocketGlyph(kind: c.glyph, size: 28, tint: c.isDC ? Pal.volt : Pal.ion)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.label).font(.label(12.5, .bold)).foregroundStyle(Pal.ink)
                            Text(c.isDC ? "Pengisian cepat" : "Pengisian harian")
                                .font(.label(10)).foregroundStyle(Pal.inkMuted)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Pal.surface))
                    .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Pal.line, lineWidth: 1))
                }
            }
        }
    }

    /// Berapa lama 20% → 80% di tiap kelas kotak pengisian yang ada di
    /// jaringan. Pakai rumus yang sama dengan yang dipakai saat mengisi
    /// betulan, jadi angkanya konsisten.
    private var chargeTable: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHead(title: "Lama isi 20% → 80%")
            VStack(spacing: 8) {
                ForEach(rungs, id: \.self) { kw in
                    let isDC = kw >= 25
                    let eff = isDC ? min(kw, max(vehicle.dcMaxKW, 0)) : min(kw, vehicle.acMaxKW)
                    let usable = eff > 0
                    let plan = Charge.Plan(capacityKWh: vehicle.batteryKWh,
                                           startSoC: 20, targetSoC: 80,
                                           ratedKW: max(eff, 0.001),
                                           taperFloor: isDC ? 0.18 : 0.6,
                                           ratePerKwh: 0, serviceFee: 0)
                    HStack(spacing: 11) {
                        Text(isDC ? "DC" : "AC")
                            .font(.label(9.5, .bold))
                            .foregroundStyle(isDC ? Pal.volt : Pal.ion)
                            .frame(width: 26, height: 22)
                            .background(Capsule().fill((isDC ? Pal.volt : Pal.ion).opacity(0.12)))
                        Text("\(Daya.kw(kw)) kW")
                            .font(.meter(13, .bold)).foregroundStyle(Pal.ink)
                            .frame(width: 62, alignment: .leading)

                        GeometryReader { geo in
                            let t = usable ? (Charge.time(plan, toReach: 80) ?? 0) : 0
                            let w = usable ? min(1, t / (6 * 3600)) : 0
                            ZStack(alignment: .leading) {
                                Capsule().fill(Pal.slab).frame(height: 7)
                                Capsule().fill(isDC ? Pal.volt : Pal.ion)
                                    .frame(width: max(6, geo.size.width * w), height: 7)
                            }
                            .frame(maxHeight: .infinity)
                        }
                        .frame(height: 22)

                        Text(usable ? Durasi.tight(Charge.time(plan, toReach: 80) ?? 0) : "tidak bisa")
                            .font(.meter(12.5, .bold))
                            .foregroundStyle(usable ? Pal.ink : Pal.inkFaint)
                            .frame(width: 62, alignment: .trailing)
                    }
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Pal.surface))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Pal.line, lineWidth: 1))

            Text("Kalau mobilnya cuma sanggup menerima daya lebih kecil dari kotaknya, yang dipakai kemampuan mobilnya — itu sebabnya beberapa baris waktunya sama.")
                .font(.label(10)).foregroundStyle(Pal.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var picker: some View {
        SlabButton(enabled: vehicle.id != store.vehicleID) {
            store.vehicleID = vehicle.id
            store.nickname = ""
            Haptic.ok()
            dismiss()
        } label: {
            HStack(spacing: 9) {
                Image(systemName: vehicle.id == store.vehicleID ? "checkmark" : "key.fill")
                    .font(.system(size: 13, weight: .bold))
                Text(vehicle.id == store.vehicleID ? "Ini kendaraan saya" : "Jadikan kendaraan saya")
                    .stencil(12.5, tracking: 1.4)
            }
            .foregroundStyle(vehicle.id == store.vehicleID ? Pal.inkFaint : Pal.void)
        }
    }
}
