import SwiftUI

/// Langkah persetujuan. Kode sudah terbaca, tapi listriknya belum
/// mengalir — di sini pemiliknya memeriksa ulang kendaraan, konektor dan
/// biayanya, lalu menahan tombol untuk setuju.
struct ConfirmSheet: View {
    let pending: PendingCharge
    @EnvironmentObject private var store: ChargeStore
    @Environment(\.dismiss) private var dismiss

    private var unit: ChargerUnit { pending.unit }
    private var fits: Bool { store.vehicle.accepts(unit) }
    private var ready: Bool { fits && unit.status.usable && store.targetSoC > store.startSoC }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                head
                connectorCard
                vehicleCard
                socRows
                bill
                if !fits {
                    Note(text: "Konektor ini \(unit.connector.label), sedangkan \(store.vehicle.displayName) pakai \(store.vehicle.ports.map(\.label).joined(separator: " / ")). Pilih konektor lain.",
                         tint: Pal.alarm, symbol: "exclamationmark.triangle.fill")
                } else if !unit.status.usable {
                    Note(text: "Kotak ini \(unit.status.label.lowercased()). Coba konektor lain di lokasi yang sama.",
                         tint: Pal.alarm, symbol: "exclamationmark.triangle.fill")
                }
                confirmArea
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .background(Pal.void)
    }

    private var head: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle().fill(Pal.volt.opacity(0.12)).frame(width: 54, height: 54)
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Pal.volt)
            }
            Text("Konektor terbaca").font(.label(17, .bold)).foregroundStyle(Pal.ink)
            Text("Periksa dulu, baru setujui.")
                .font(.label(12)).foregroundStyle(Pal.inkMuted)
        }
    }

    private var connectorCard: some View {
        HStack(spacing: 13) {
            SocketGlyph(kind: unit.connector.glyph, size: 32, tint: Pal.volt)
                .frame(width: 50, height: 50)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Pal.volt.opacity(0.1)))
            VStack(alignment: .leading, spacing: 3) {
                Text(pending.place.name).font(.label(14, .bold)).foregroundStyle(Pal.ink)
                    .lineLimit(1)
                Text("\(unit.title) · \(unit.headline)")
                    .font(.label(10.5)).foregroundStyle(Pal.inkMuted)
                Text(unit.code).font(.meter(10.5, .bold)).foregroundStyle(Pal.inkFaint)
            }
            Spacer(minLength: 4)
            StatusTag(status: unit.status, compact: true)
        }
        .padding(13)
        .background(RoundedRectangle(cornerRadius: 17, style: .continuous).fill(Pal.surface))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Pal.line, lineWidth: 1))
    }

    private var vehicleCard: some View {
        HStack(spacing: 13) {
            VehicleImage(vehicle: store.vehicle, height: 48, tint: Pal.ion, fill: true)
                .frame(width: 76)
            VStack(alignment: .leading, spacing: 3) {
                Text(store.vehicleLabel).font(.label(14, .bold)).foregroundStyle(Pal.ink)
                    .lineLimit(1)
                Text("\(Energi.kwh(store.vehicle.batteryKWh)) kWh · terima \(Daya.kw(store.vehicle.effectiveKW(on: unit))) kW")
                    .font(.label(10.5)).foregroundStyle(Pal.inkMuted)
            }
            Spacer(minLength: 4)
        }
        .padding(13)
        .background(RoundedRectangle(cornerRadius: 17, style: .continuous).fill(Pal.surface))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Pal.line, lineWidth: 1))
    }

    private var socRows: some View {
        VStack(spacing: 15) {
            socRow(caption: "Baterai Sekarang", value: $store.startSoC,
                   tint: Pal.inkMuted, lower: 0)
            socRow(caption: "Isi Sampai", value: $store.targetSoC,
                   tint: Pal.volt, lower: store.startSoC + 1, presets: true)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 17, style: .continuous).fill(Pal.surface))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Pal.line, lineWidth: 1))
    }

    private func socRow(caption: String, value: Binding<Double>, tint: Color,
                        lower: Double, presets: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(caption).stencil(9.5, tracking: 1.3).foregroundStyle(Pal.inkMuted)
                Spacer()
                Text("\(Energi.persen(value.wrappedValue))%")
                    .font(.meter(16, .bold))
                    .foregroundStyle(tint == Pal.inkMuted ? Pal.ink : tint)
            }
            SocSlider(value: value, tint: tint == Pal.inkMuted ? Pal.inkFaint : tint,
                      lowerBound: lower)
            if presets {
                HStack(spacing: 7) {
                    ForEach([80.0, 90.0, 100.0], id: \.self) { v in
                        Chip(text: "\(Int(v))%", on: value.wrappedValue == v) {
                            value.wrappedValue = max(v, store.startSoC + 1)
                        }
                    }
                }
            }
        }
    }

    private var bill: some View {
        let est = store.estimate(for: unit)
        return VStack(spacing: 12) {
            MetricStrip(items: [
                .init(caption: "Perkiraan", value: est.duration.map(Durasi.tight) ?? "—"),
                .init(caption: "Listrik Masuk", value: Energi.kwh(est.energy), unit: "kWh"),
                .init(caption: "Tambah Jarak", value: "\(est.km)", unit: "km", tint: Pal.ion),
            ])
            Rectangle().fill(Pal.line).frame(height: 1)
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Perkiraan Bayar").stencil(9, tracking: 1.2).foregroundStyle(Pal.inkMuted)
                    Text("\(Rupiah.decimal(unit.ratePerKwh))/kWh" +
                         (unit.serviceFee > 0 ? "  +  layanan \(Rupiah.full(unit.serviceFee))" : ""))
                        .font(.label(10.5)).foregroundStyle(Pal.inkFaint)
                }
                Spacer()
                PriceTag(value: est.cost, size: 26, color: Pal.volt)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 17, style: .continuous).fill(Pal.surface))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Pal.line, lineWidth: 1))
    }

    private var confirmArea: some View {
        VStack(spacing: 11) {
            if ready {
                HoldToConfirm(title: "Tahan untuk mulai mengisi",
                              tint: Pal.volt, icon: "bolt.fill", duration: 1.0) {
                    store.confirmPending()
                    dismiss()
                }
            } else {
                SlabButton(enabled: false, action: {}) {
                    Text("Belum bisa dimulai").stencil(12.5, tracking: 1.4)
                        .foregroundStyle(Pal.inkFaint)
                }
            }
            Button {
                store.pending = nil
                dismiss()
            } label: {
                Text("Batal").font(.label(13, .semibold)).foregroundStyle(Pal.inkMuted)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            Text("Dengan menahan tombol, kamu setuju listrik mulai mengalir dan biayanya dihitung sejak detik itu.")
                .font(.label(10))
                .foregroundStyle(Pal.inkFaint)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
