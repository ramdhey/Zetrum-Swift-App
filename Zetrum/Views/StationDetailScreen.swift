import SwiftUI

struct StationDetailScreen: View {
    let place: Place
    @EnvironmentObject private var store: ChargeStore
    @Environment(\.dismiss) private var dismiss
    @State private var tab = 0
    @State private var openUnit: String?

    var body: some View {
        ZStack(alignment: .top) {
            Pal.void.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    banner
                    VStack(alignment: .leading, spacing: 16) {
                        headline
                        actions
                        tabBar
                        switch tab {
                        case 0: unitsTab
                        case 1: reviewsTab
                        default: facilitiesTab
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)

            HStack {
                BackButton { dismiss() }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .presentationBackground(Pal.void)
    }

    // MARK: Kepala

    /// Tidak ada foto lokasi, jadi kepalanya digambar: gradasi gelap,
    /// lambang jenis tempatnya besar, dan pola kilat samar.
    private var banner: some View {
        ZStack {
            LinearGradient(colors: [Pal.volt.opacity(0.22), Pal.void],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            GeometryReader { geo in
                ForEach(0..<9, id: \.self) { i in
                    Bolt()
                        .fill(Pal.volt.opacity(0.05))
                        .frame(width: 26, height: 36)
                        .rotationEffect(.degrees(-12))
                        .position(x: CGFloat(i % 3) * geo.size.width / 2.4 + 46,
                                  y: CGFloat(i / 3) * 62 + 44)
                }
            }
            Image(systemName: place.venue.symbol)
                .font(.system(size: 62, weight: .regular))
                .foregroundStyle(Pal.volt.opacity(0.9))
                .shadow(color: Pal.volt.opacity(0.3), radius: 22)
            VStack {
                Spacer()
                LinearGradient(colors: [.clear, Pal.void], startPoint: .top, endPoint: .bottom)
                    .frame(height: 70)
            }
        }
        .frame(height: 210)
        .clipped()
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(place.name)
                        .font(.label(21, .bold)).foregroundStyle(Pal.ink)
                    Text(place.address + ", " + place.city)
                        .font(.label(12)).foregroundStyle(Pal.inkMuted)
                }
                Spacer(minLength: 4)
                BoltMark(size: 34)
            }
            HStack(spacing: 7) {
                HStack(spacing: 5) {
                    Circle().fill(place.open24 ? Pal.volt : Pal.ion).frame(width: 6, height: 6)
                    Text(place.hours).font(.label(11.5, .semibold))
                        .foregroundStyle(place.open24 ? Pal.volt : Pal.ion)
                }
                Text("·").foregroundStyle(Pal.inkFaint)
                Text("★ \(Energi.kwh(place.rating, decimals: 2))")
                    .font(.label(11.5, .semibold)).foregroundStyle(Pal.ink)
                Text("(\(place.reviews))").font(.label(11)).foregroundStyle(Pal.inkFaint)
                Text("·").foregroundStyle(Pal.inkFaint)
                Text(Jarak.near(store.distance(to: place)))
                    .font(.label(11.5)).foregroundStyle(Pal.inkMuted)
            }
            HStack(spacing: 7) {
                Chip(text: "\(place.totalUnits) Kotak Pengisian", symbol: "square.grid.2x2.fill")
                Chip(text: "\(place.available)/\(place.totalUnits) Tersedia",
                     symbol: "powerplug.portrait.fill",
                     on: place.available > 0)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 9) {
            Button {
                Haptic.tick()
                let u = "http://maps.apple.com/?daddr=\(place.lat),\(place.lon)&dirflg=d"
                if let url = URL(string: u) { UIApplication.shared.open(url) }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "location.fill").font(.system(size: 12, weight: .bold))
                    Text("Navigasi").font(.label(13.5, .bold))
                }
                .foregroundStyle(Pal.void)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Pal.volt))
            }
            .buttonStyle(.plain)

            ForEach(["heart", "square.and.arrow.up"], id: \.self) { icon in
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Pal.inkMuted)
                    .frame(width: 46, height: 46)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Pal.slab))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Pal.line, lineWidth: 1))
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(["Kotak Pengisian", "Ulasan", "Fasilitas"].enumerated()), id: \.offset) { i, t in
                Button {
                    Haptic.tick()
                    withAnimation(.easeOut(duration: 0.2)) { tab = i }
                } label: {
                    VStack(spacing: 8) {
                        Text(t).font(.label(12.5, tab == i ? .bold : .medium))
                            .foregroundStyle(tab == i ? Pal.ink : Pal.inkMuted)
                        Rectangle()
                            .fill(tab == i ? Pal.volt : .clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(alignment: .bottom) { Rectangle().fill(Pal.line).frame(height: 1) }
    }

    // MARK: Kotak pengisian

    private var unitsTab: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.clockwise").font(.system(size: 9, weight: .bold))
                Text("Diperbarui \(Self.clock)").font(.label(10.5))
                Spacer()
            }
            .foregroundStyle(Pal.inkFaint)

            ForEach(place.units) { unit in
                UnitCard(place: place, unit: unit,
                         open: openUnit == unit.id,
                         onToggle: {
                             withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                                 openUnit = openUnit == unit.id ? nil : unit.id
                             }
                         })
            }

            if !place.units.contains(where: { store.vehicle.accepts($0) }) {
                Note(text: "Tidak ada konektor di sini yang cocok dengan \(store.vehicle.displayName). Kendaraan itu pakai \(store.vehicle.ports.map(\.label).joined(separator: " / ")).",
                     tint: Pal.alarm, symbol: "exclamationmark.triangle.fill")
            } else {
                Note(text: "Konektor sedang dipakai? Pindai kode QR di badan charger untuk masuk antrean.",
                     tint: Pal.ion, symbol: "qrcode.viewfinder")
            }
        }
    }

    private static var clock: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: Date())
    }

    // MARK: Ulasan

    private var reviewsTab: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(Energi.kwh(place.rating, decimals: 2))
                    .font(.meter(38, .bold)).foregroundStyle(Pal.ink)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: Double(i) + 0.5 < place.rating ? "star.fill" : "star")
                                .font(.system(size: 11))
                                .foregroundStyle(Pal.volt)
                        }
                    }
                    Text("\(place.reviews) ulasan").font(.label(11)).foregroundStyle(Pal.inkMuted)
                }
                Spacer()
            }
            Rectangle().fill(Pal.line).frame(height: 1)
            ForEach(Review.forPlace(place)) { r in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(r.initials)
                            .font(.label(11, .bold)).foregroundStyle(Pal.void)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Pal.volt.opacity(0.8)))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(r.name).font(.label(13, .semibold)).foregroundStyle(Pal.ink)
                            Text(r.when).font(.label(10)).foregroundStyle(Pal.inkFaint)
                        }
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { i in
                                Image(systemName: i < r.stars ? "star.fill" : "star")
                                    .font(.system(size: 8))
                                    .foregroundStyle(i < r.stars ? Pal.volt : Pal.inkFaint)
                            }
                        }
                    }
                    Text(r.text).font(.label(12.5)).foregroundStyle(Pal.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(13)
                .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Pal.surface))
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(Pal.line, lineWidth: 1))
            }
        }
    }

    // MARK: Fasilitas

    private var facilitiesTab: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("Yang bisa dipakai sambil menunggu")
                .font(.label(12.5)).foregroundStyle(Pal.inkMuted)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 3),
                      spacing: 9) {
                ForEach(Facility.allCases) { f in
                    let has = place.facilities.contains(f)
                    VStack(spacing: 8) {
                        Image(systemName: f.symbol)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(has ? Pal.volt : Pal.inkFaint.opacity(0.5))
                        Text(f.label)
                            .font(.label(10.5, .medium))
                            .foregroundStyle(has ? Pal.ink : Pal.inkFaint.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(has ? Pal.surface : Pal.surface.opacity(0.4)))
                    .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(has ? Pal.line : .clear, lineWidth: 1))
                }
            }
            Note(text: place.open24
                 ? "Lokasi ini buka 24 jam, jadi aman kalau kendaraannya ditinggal semalam."
                 : "Jam buka \(place.hours). Pastikan pengisiannya selesai sebelum tutup.",
                 tint: Pal.ion, symbol: "clock.fill")
        }
    }
}

// MARK: - Satu kotak pengisian

private struct UnitCard: View {
    let place: Place
    let unit: ChargerUnit
    let open: Bool
    var onToggle: () -> Void
    @EnvironmentObject private var store: ChargeStore

    private var fits: Bool { store.vehicle.accepts(unit) }
    private var canStart: Bool { fits && unit.status.usable && store.active == nil }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    SocketGlyph(kind: unit.connector.glyph, size: 26,
                                tint: unit.status.usable ? Pal.volt : Pal.inkFaint)
                        .frame(width: 42, height: 42)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill((unit.status.usable ? Pal.volt : Pal.inkFaint).opacity(0.1)))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(unit.title).font(.label(14, .bold)).foregroundStyle(Pal.ink)
                        Text("1 Konektor · \(unit.connector.short)")
                            .font(.label(10.5)).foregroundStyle(Pal.inkMuted)
                    }
                    Spacer(minLength: 4)
                    Text(unit.powerLabel)
                        .font(.meter(14, .bold))
                        .foregroundStyle(unit.connector.isDC ? Pal.volt : Pal.ion)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Pal.inkFaint)
                        .rotationEffect(.degrees(open ? 180 : 0))
                }
                .padding(13)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if open {
                VStack(alignment: .leading, spacing: 11) {
                    Rectangle().fill(Pal.line).frame(height: 1)
                    HStack(alignment: .top, spacing: 13) {
                        SocketGlyph(kind: unit.connector.glyph, size: 40, tint: Pal.ink)
                            .frame(width: 52, height: 52)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(unit.headline).font(.label(14, .bold)).foregroundStyle(Pal.ink)
                            Text("\(Rupiah.decimal(unit.ratePerKwh))/kWh")
                                .font(.label(12)).foregroundStyle(Pal.inkMuted)
                            Text("Biaya Layanan : \(unit.serviceFee == 0 ? "Rp0" : Rupiah.full(unit.serviceFee))")
                                .font(.label(11)).foregroundStyle(Pal.inkFaint)
                            StatusTag(status: unit.status).padding(.top, 2)
                        }
                        Spacer()
                    }

                    if fits {
                        let est = store.estimate(for: unit)
                        MetricStrip(items: [
                            .init(caption: "Perkiraan", value: est.duration.map(Durasi.tight) ?? "—"),
                            .init(caption: "Masuk", value: Energi.kwh(est.energy), unit: "kWh"),
                            .init(caption: "Bayar", value: Rupiah.plain(est.cost), unit: "Rp",
                                  tint: Pal.volt),
                        ])
                        Text("Dihitung untuk \(store.vehicleLabel) dari \(Energi.persen(store.startSoC))% ke \(Energi.persen(store.targetSoC))%, daya nyata \(Daya.kw(store.vehicle.effectiveKW(on: unit))) kW.")
                            .font(.label(10.5)).foregroundStyle(Pal.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Konektor \(unit.connector.label) tidak cocok dengan \(store.vehicle.displayName).")
                            .font(.label(11.5)).foregroundStyle(Pal.alarm)
                    }

                    SlabButton(tint: Pal.volt, enabled: canStart) {
                        store.offer(place, unit)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill").font(.system(size: 13, weight: .bold))
                            Text(buttonTitle).stencil(12.5, tracking: 1.4)
                        }
                        .foregroundStyle(canStart ? Pal.void : Pal.inkFaint)
                    }
                }
                .padding(13)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(RoundedRectangle(cornerRadius: 17, style: .continuous).fill(Pal.surface))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous)
            .stroke(open ? Pal.volt.opacity(0.35) : Pal.line, lineWidth: 1))
    }

    private var buttonTitle: String {
        if store.active != nil { return "Masih ada sesi berjalan" }
        if !fits { return "Konektor tidak cocok" }
        switch unit.status {
        case .idle:   return "Pilih konektor ini"
        case .busy:   return "Sedang digunakan"
        case .broken: return "Dalam perbaikan"
        }
    }
}

// MARK: - Catatan kecil

struct Note: View {
    var text: String
    var tint: Color = Pal.ion
    var symbol: String = "info.circle.fill"

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)
            Text(text)
                .font(.label(11.5))
                .foregroundStyle(Pal.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tint.opacity(0.07)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(tint.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Ulasan contoh

struct Review: Identifiable {
    var id = UUID()
    var name: String
    var initials: String
    var stars: Int
    var when: String
    var text: String

    /// Dibuat tetap per lokasi, bukan diacak tiap kali layar dibuka.
    static func forPlace(_ p: Place) -> [Review] {
        let names = ["Rizky Pratama", "Dewi Anggraini", "Bagus Setiawan", "Nadia Putri",
                     "Fajar Nugroho", "Sari Wulandari", "Andi Kurniawan", "Maya Lestari"]
        let whens = ["2 hari lalu", "seminggu lalu", "2 minggu lalu", "bulan lalu"]
        let good = [
            "Chargernya gampang dipakai, sekali tempel kartu langsung jalan. Parkirnya juga luas.",
            "Ditinggal makan sebentar, balik-balik sudah 80%. Puas.",
            "Posisinya gampang dicari, petugasnya bantu colokin kabel.",
            "Dari 20% ke 80% cuma setengah jam. Tarifnya sesuai aplikasi.",
            "Tempatnya teduh dan bersih, ada musala. Cocok buat nunggu lama.",
        ]
        let mixed = [
            "Antre lumayan karena cuma ada beberapa kotak. Datang pagi lebih aman.",
            "Satu konektor lagi diperbaiki, jadi harus gantian. Sisanya oke.",
            "Kabelnya agak pendek, mobil harus mundur pas banget.",
        ]
        var seed = UInt64(abs(p.id.hashValue % 100_000)) &+ 7
        func next(_ n: Int) -> Int {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Int(seed >> 33) % max(1, n)
        }
        return (0..<3).map { i in
            let strong = p.rating >= 4.5 || i == 0
            let name = names[next(names.count)]
            return Review(
                name: name,
                initials: name.split(separator: " ").compactMap { $0.first }.map(String.init)
                    .prefix(2).joined(),
                stars: strong ? 5 : 4,
                when: whens[next(whens.count)],
                text: strong ? good[next(good.count)] : mixed[next(mixed.count)])
        }
    }
}
