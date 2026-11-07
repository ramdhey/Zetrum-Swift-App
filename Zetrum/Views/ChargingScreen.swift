import SwiftUI

/// Layar pengisian. Satu layar penuh dipakai dua keadaan: sedang mengisi
/// (hijau setrum) dan sudah penuh (biru es). Perpindahannya dianimasikan,
/// bukan ganti layar — supaya terasa mobil yang sama, bukan halaman lain.
struct ChargingScreen: View {
    @EnvironmentObject private var store: ChargeStore
    var onClose: () -> Void
    var onStop: () -> Void

    private var accent: Color { store.isFull ? Pal.ion : Pal.volt }

    var body: some View {
        ZStack {
            DashBackground(warm: accent)

            if let session = store.active {
                ScrollView {
                    VStack(spacing: 18) {
                        bar
                        stationCard(session)
                        hero(session)
                        countdown
                        metrics(session)
                        billing(session)
                        stopArea
                        footnote
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 34)
                }
                .scrollIndicators(.hidden)
            } else {
                VStack(spacing: 14) {
                    Text("Tidak ada pengisian berjalan")
                        .font(.label(15, .semibold)).foregroundStyle(Pal.inkMuted)
                    Button("Tutup", action: onClose).foregroundStyle(Pal.volt)
                }
            }
        }
        .animation(.easeInOut(duration: 0.8), value: store.isFull)
    }

    // MARK: Bar atas

    private var bar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Pal.ink)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Pal.surface))
                    .overlay(Circle().stroke(Pal.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            Spacer()
            HStack(spacing: 7) {
                Circle().fill(accent).frame(width: 7, height: 7)
                Text(store.isFull ? "Sudah Penuh" : "Sedang Mengisi")
                    .stencil(11.5, tracking: 2)
                    .foregroundStyle(accent)
            }
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.top, 12)
    }

    // MARK: Lokasi

    private func stationCard(_ s: ChargeSession) -> some View {
        HStack(spacing: 12) {
            SocketGlyph(kind: s.unit.connector.glyph, size: 26, tint: accent)
                .frame(width: 42, height: 42)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accent.opacity(0.1)))
            VStack(alignment: .leading, spacing: 3) {
                Text(s.place.name).font(.label(14, .bold)).foregroundStyle(Pal.ink).lineLimit(1)
                Text("\(s.unit.title) · \(s.unit.connector.label) · \(s.unit.code)")
                    .font(.label(10.5)).foregroundStyle(Pal.inkMuted).lineLimit(1)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 2) {
                Text(Daya.kw(s.vehicle.effectiveKW(on: s.unit)))
                    .font(.meter(15, .bold)).foregroundStyle(accent)
                Text("kW maks").font(.label(9)).foregroundStyle(Pal.inkFaint)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 17, style: .continuous).fill(Pal.surface))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Pal.line, lineWidth: 1))
    }

    // MARK: Angka besar

    private func hero(_ s: ChargeSession) -> some View {
        VStack(spacing: 16) {
            VehicleImage(vehicle: s.vehicle, height: 92, tint: accent)
                .opacity(0.92)

            HStack(alignment: .firstTextBaseline) {
                UnitTag(text: Energi.persen(store.soc), unit: "%", size: 60, color: Pal.ink)
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Target").stencil(9, tracking: 1.2).foregroundStyle(Pal.inkMuted)
                    Text("\(Energi.persen(s.targetSoC))%")
                        .font(.meter(18, .bold)).foregroundStyle(accent)
                }
            }

            BatteryPack(soc: store.soc, target: s.targetSoC, tint: accent,
                        charging: !store.isFull, cells: 26, height: 38)

            HStack {
                Text("Mulai dari \(Energi.persen(s.startSoC))%")
                    .font(.label(10.5)).foregroundStyle(Pal.inkFaint)
                Spacer()
                Text("+\(store.addedKm) km jarak tempuh")
                    .font(.label(10.5, .semibold)).foregroundStyle(Pal.ion)
            }
        }
        .padding(17)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Pal.surface))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(accent.opacity(0.25), lineWidth: 1))
    }

    // MARK: Hitung mundur

    @ViewBuilder
    private var countdown: some View {
        if store.isFull {
            HStack(spacing: 11) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 19, weight: .bold)).foregroundStyle(Pal.ion)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pengisian selesai").font(.label(14.5, .bold)).foregroundStyle(Pal.ion)
                    Text("Silakan cabut konektornya supaya tidak kena biaya diam.")
                        .font(.label(11)).foregroundStyle(Pal.inkMuted)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 17, style: .continuous).fill(Pal.ion.opacity(0.1)))
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Pal.ion.opacity(0.3), lineWidth: 1))
        } else if let finish = store.finishAt {
            HStack(spacing: 11) {
                Image(systemName: "hourglass")
                    .font(.system(size: 17, weight: .bold)).foregroundStyle(Pal.volt)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Penuh dalam").stencil(9, tracking: 1.2).foregroundStyle(Pal.inkMuted)
                    Text(timerInterval: Date()...max(finish, Date().addingTimeInterval(1)),
                         countsDown: true)
                        .font(.meter(24, .bold))
                        .foregroundStyle(Pal.ink)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Perkiraan Jam").stencil(9, tracking: 1.2).foregroundStyle(Pal.inkMuted)
                    Text(finish, format: .dateTime.hour().minute())
                        .font(.meter(16, .bold)).foregroundStyle(Pal.volt)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 17, style: .continuous).fill(Pal.surface))
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Pal.line, lineWidth: 1))
        }
    }

    // MARK: Empat angka

    private func metrics(_ s: ChargeSession) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2),
                  spacing: 10) {
            cell("Listrik Masuk", Energi.kwh(store.energy), "kWh", Pal.ink)
            cell("Daya Sekarang", store.isFull ? "0" : Daya.kw(store.power), "kW",
                 store.isFull ? Pal.inkFaint : Pal.volt)
            cell("Sudah Jalan", Durasi.clock(s.elapsed(at: store.now)), nil, Pal.ink)
            cell("Baterai Terisi", Energi.kwh(store.soc - s.startSoC, decimals: 1), "%", Pal.ion)
        }
    }

    private func cell(_ caption: String, _ value: String, _ unit: String?, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(caption).stencil(8.5, tracking: 1.2).foregroundStyle(Pal.inkMuted)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Odometer(text: value, size: 21, color: tint)
                if let unit {
                    Text(unit).font(.label(11, .semibold)).foregroundStyle(Pal.inkFaint)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 17, style: .continuous).fill(Pal.surface))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Pal.line, lineWidth: 1))
    }

    // MARK: Biaya

    private func billing(_ s: ChargeSession) -> some View {
        VStack(spacing: 11) {
            HStack {
                Text("Biaya Berjalan").stencil(10, tracking: 1.6).foregroundStyle(Pal.inkMuted)
                Spacer()
                Text("\(Rupiah.decimal(s.unit.ratePerKwh))/kWh")
                    .font(.label(11)).foregroundStyle(Pal.inkFaint)
            }
            HStack(alignment: .firstTextBaseline) {
                PriceTag(value: store.cost, size: 40, color: accent)
                Spacer()
            }
            if s.unit.serviceFee > 0 {
                HStack {
                    Text("Sudah termasuk biaya layanan \(Rupiah.full(s.unit.serviceFee))")
                        .font(.label(10.5)).foregroundStyle(Pal.inkFaint)
                    Spacer()
                }
            }
        }
        .padding(17)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Pal.surface))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(accent.opacity(0.25), lineWidth: 1))
    }

    private var stopArea: some View {
        HoldToConfirm(title: store.isFull ? "Tahan untuk cabut & bayar" : "Tahan untuk hentikan",
                      tint: store.isFull ? Pal.ion : Pal.alarm,
                      duration: 0.9) {
            onStop()
        }
    }

    private var footnote: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.iphone").font(.system(size: 10, weight: .bold))
            Text(store.isFull
                 ? "Kabar sudah dikirim — kendaraan boleh dijemput"
                 : "Boleh ditinggal. Kartunya terus menghitung di layar kunci.")
                .font(.label(10.5))
        }
        .foregroundStyle(Pal.inkFaint)
    }
}
