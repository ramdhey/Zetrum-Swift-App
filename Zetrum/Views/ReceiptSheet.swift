import SwiftUI

/// Struk. Bentuknya karcis sungguhan — ada takikan sobek dan garis
/// perforasi — karena ini satu-satunya layar yang benar-benar "kertas".
struct ReceiptSheet: View {
    let session: ChargeSession
    @Environment(\.dismiss) private var dismiss

    private var ended: Date { session.endedAt ?? Date() }
    private var endSoC: Double { session.soc(at: ended) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                TicketCard(fill: Pal.receipt, stroke: .clear, corner: 20) {
                    VStack(spacing: 0) {
                        head
                        rows
                        Perforation(color: Pal.receiptInk.opacity(0.28))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                        total
                    }
                }
                closeButton
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 22)
        }
        .scrollIndicators(.hidden)
        .background(Pal.void)
        .presentationBackground(Pal.void)
    }

    private var head: some View {
        VStack(spacing: 9) {
            HStack(spacing: 8) {
                Bolt().fill(Pal.receiptInk).frame(width: 13, height: 18)
                Text("ZETRUM").stencil(13, tracking: 3.4).foregroundStyle(Pal.receiptInk)
            }
            Text("BUKTI PENGISIAN").stencil(8.5, tracking: 2)
                .foregroundStyle(Pal.receiptInk.opacity(0.5))
            Text(session.place.name)
                .font(.label(14, .bold)).foregroundStyle(Pal.receiptInk)
                .multilineTextAlignment(.center)
            Text(session.place.address)
                .font(.label(10)).foregroundStyle(Pal.receiptInk.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 16)
    }

    private var rows: some View {
        VStack(spacing: 9) {
            Rectangle().fill(Pal.receiptInk.opacity(0.12)).frame(height: 1)
            line("Kendaraan", session.vehicle.displayName)
            line("Konektor", "\(session.unit.title) · \(session.unit.connector.label)")
            line("Kode", session.unit.code)
            line("Mulai", Self.stamp(session.startedAt))
            line("Selesai", Self.stamp(ended))
            line("Lama", Durasi.humane(session.elapsed()))
            Rectangle().fill(Pal.receiptInk.opacity(0.12)).frame(height: 1)
            line("Baterai", "\(Energi.persen(session.startSoC))% → \(Energi.persen(endSoC))%")
            line("Listrik Masuk", "\(Energi.kwh(session.energy(at: ended), decimals: 2)) kWh")
            line("Tambah Jarak", "\(session.addedKm(at: ended)) km")
            line("Tarif", "\(Rupiah.decimal(session.unit.ratePerKwh))/kWh")
            if session.unit.serviceFee > 0 {
                line("Biaya Layanan", Rupiah.full(session.unit.serviceFee))
            }
        }
        .padding(.horizontal, 20)
    }

    private func line(_ k: String, _ v: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(k).font(.label(11.5)).foregroundStyle(Pal.receiptInk.opacity(0.55))
            Spacer(minLength: 10)
            Text(v).font(.label(11.5, .semibold)).foregroundStyle(Pal.receiptInk)
                .multilineTextAlignment(.trailing)
        }
    }

    private var total: some View {
        VStack(spacing: 13) {
            HStack(alignment: .firstTextBaseline) {
                Text("TOTAL").stencil(10.5, tracking: 2).foregroundStyle(Pal.receiptInk.opacity(0.6))
                Spacer()
                PriceTag(value: session.cost(at: ended), size: 30, color: Pal.receiptInk)
            }
            Barcode(seed: session.id.uuidString)
                .frame(height: 38)
            Text(session.id.uuidString.prefix(18).uppercased())
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Pal.receiptInk.opacity(0.4))
            Text("Terima kasih sudah pakai listrik.")
                .font(.label(10)).foregroundStyle(Pal.receiptInk.opacity(0.45))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
    }

    private var closeButton: some View {
        SlabButton(tint: Pal.volt) { dismiss() } label: {
            Text("Tutup").stencil(12.5, tracking: 1.6).foregroundStyle(Pal.void)
        }
    }

    private static func stamp(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "id_ID")
        f.dateFormat = "d MMM yyyy, HH:mm"
        return f.string(from: d)
    }
}

/// Garis-garis barcode yang lebarnya ditentukan id sesi — jadi tiap struk
/// polanya beda tapi tetap sama kalau dibuka lagi.
private struct Barcode: View {
    let seed: String

    var body: some View {
        GeometryReader { geo in
            let bytes = Array(seed.utf8)
            let n = 58
            HStack(spacing: 1.6) {
                ForEach(0..<n, id: \.self) { i in
                    let b = bytes[i % bytes.count]
                    Rectangle()
                        .fill(Pal.receiptInk.opacity(b % 3 == 0 ? 0.15 : 0.85))
                        .frame(width: b % 4 == 0 ? 2.6 : 1.3)
                }
            }
            .frame(width: geo.size.width, alignment: .center)
        }
    }
}
