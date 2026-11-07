import Foundation

// MARK: - Daftar SPKLU Zetrum

/// Titik-titiknya nyata: rumah sakit, stadion, stasiun, mal, rest area dan
/// bandara di Jabodetabek, dengan koordinat sebenarnya supaya markernya
/// jatuh di tempat yang benar di peta. Merek, nomor kotak pengisian dan
/// keadaannya karangan — ini aplikasi contoh, bukan data operasional PLN.
///
/// Tarif memakai skema PLN: Rp 2.466,78/kWh untuk pengisian normal dan
/// cepat, dengan biaya layanan untuk kotak di atas 50 kW.
enum Zetrum {

    static let normalRate: Double = 2_466.78
    static let ultraRate: Double  = 2_466.78

    private static func unit(_ id: String, _ maker: String, _ model: String,
                             _ c: Connector, _ kW: Double, _ status: UnitStatus,
                             fee: Int = 0) -> ChargerUnit {
        .init(id: id, maker: maker, model: model, connector: c, kW: kW,
              ratePerKwh: kW > 50 ? ultraRate : normalRate,
              serviceFee: fee, status: status)
    }

    static let places: [Place] = [

        // ───────────── Rumah sakit ─────────────
        .init(id: "rscm", name: "Zetrum RSCM Kencana", venue: .hospital,
              address: "Jl. Diponegoro No. 71, Kenari, Senen",
              city: "Jakarta Pusat", lat: -6.19600, lon: 106.84640,
              open24: true, hours: "Buka 24 Jam", rating: 4.7, reviews: 318,
              facilities: [.toilet, .musholla, .minimarket, .cafe, .parking, .atm],
              units: [
                unit("rscm-1", "Delta", "AC Max", .type2, 22, .idle),
                unit("rscm-2", "Star Charge", "Nova 60", .ccs2, 60, .busy, fee: 25_000),
                unit("rscm-3", "Delta", "AC Max", .type2, 7.4, .idle),
                unit("rscm-r2", "Zetrum", "R2 Motor", .shuko, 2.2, .idle),
              ]),

        .init(id: "pondok-indah", name: "Zetrum RS Pondok Indah – Puri Indah", venue: .hospital,
              address: "Jl. Puri Indah Raya Blok S-2, Kembangan Selatan",
              city: "Jakarta Barat", lat: -6.18770, lon: 106.73680,
              open24: true, hours: "Buka 24 Jam", rating: 4.8, reviews: 194,
              facilities: [.toilet, .musholla, .cafe, .parking, .wifi, .lounge],
              units: [
                unit("pi-1", "ABB", "Terra 54", .ccs2, 50, .idle),
                unit("pi-2", "Delta", "AC Max", .type2, 22, .idle),
              ]),

        .init(id: "fatmawati", name: "Zetrum RSUP Fatmawati", venue: .hospital,
              address: "Jl. RS Fatmawati Raya No. 4, Cilandak Barat",
              city: "Jakarta Selatan", lat: -6.29250, lon: 106.79680,
              open24: true, hours: "Buka 24 Jam", rating: 4.4, reviews: 126,
              facilities: [.toilet, .musholla, .minimarket, .parking],
              units: [
                unit("fat-1", "Delta", "AC Max", .type2, 7.4, .idle),
                unit("fat-2", "Delta", "AC Max", .type2, 7.4, .broken),
              ]),

        .init(id: "siloam-bekasi", name: "Zetrum Siloam Hospitals Bekasi", venue: .hospital,
              address: "Jl. Chairil Anwar No. 29, Margahayu, Bekasi Timur",
              city: "Kota Bekasi", lat: -6.24180, lon: 107.00430,
              open24: true, hours: "Buka 24 Jam", rating: 4.5, reviews: 88,
              facilities: [.toilet, .musholla, .minimarket, .cafe, .parking],
              units: [
                unit("sib-1", "Star Charge", "Nova 60", .ccs2, 60, .idle, fee: 25_000),
                unit("sib-2", "Autel", "MaxiCharger AC", .type2, 11, .idle),
              ]),

        // ───────────── Stadion ─────────────
        .init(id: "gbk", name: "Zetrum GBK Senayan", venue: .stadium,
              address: "Kompleks GBK, Pintu VII, Gelora, Tanah Abang",
              city: "Jakarta Pusat", lat: -6.21850, lon: 106.80200,
              open24: true, hours: "Buka 24 Jam", rating: 4.9, reviews: 742,
              facilities: [.toilet, .musholla, .minimarket, .cafe, .parking, .wifi, .atm, .restaurant],
              units: [
                unit("gbk-1", "Sinexcel", "Ultra 200", .ccs2, 200, .idle, fee: 57_000),
                unit("gbk-2", "Star Charge", "Atlas 120", .ccs2, 120, .idle, fee: 57_000),
                unit("gbk-3", "Star Charge", "Atlas 120", .ccs2, 120, .busy, fee: 57_000),
                unit("gbk-4", "Delta", "AC Max", .type2, 22, .idle),
                unit("gbk-r2", "Zetrum", "R2 Motor", .shuko, 2.2, .idle),
              ]),

        .init(id: "jis", name: "Zetrum Jakarta International Stadium", venue: .stadium,
              address: "Jl. RE Martadinata, Papanggo, Tanjung Priok",
              city: "Jakarta Utara", lat: -6.12660, lon: 106.85300,
              open24: false, hours: "06.00 – 23.00", rating: 4.6, reviews: 263,
              facilities: [.toilet, .musholla, .minimarket, .parking, .wifi],
              units: [
                unit("jis-1", "Star Charge", "Atlas 120", .ccs2, 120, .idle, fee: 57_000),
                unit("jis-2", "Delta", "AC Max", .type2, 22, .idle),
                unit("jis-3", "Delta", "AC Max", .type2, 22, .busy),
                unit("jis-r2", "Zetrum", "R2 Motor", .shuko, 2.2, .idle),
              ]),

        .init(id: "pakansari", name: "Zetrum Stadion Pakansari", venue: .stadium,
              address: "Jl. Tegar Beriman, Pakansari, Cibinong",
              city: "Kabupaten Bogor", lat: -6.47560, lon: 106.83950,
              open24: false, hours: "07.00 – 22.00", rating: 4.2, reviews: 54,
              facilities: [.toilet, .musholla, .parking],
              units: [
                unit("pak-1", "ABB", "Terra 54", .ccs2, 50, .idle),
                unit("pak-r2", "Zetrum", "R2 Motor", .shuko, 2.2, .idle),
              ]),

        .init(id: "patriot", name: "Zetrum Stadion Patriot Candrabhaga", venue: .stadium,
              address: "Jl. Guntur, Kayuringin Jaya, Bekasi Selatan",
              city: "Kota Bekasi", lat: -6.23360, lon: 106.99050,
              open24: false, hours: "07.00 – 22.00", rating: 4.3, reviews: 71,
              facilities: [.toilet, .musholla, .minimarket, .parking],
              units: [
                unit("pat-1", "Star Charge", "Nova 60", .ccs2, 60, .idle, fee: 25_000),
                unit("pat-2", "Delta", "AC Max", .type2, 7.4, .idle),
                unit("pat-r2", "Zetrum", "R2 Motor", .shuko, 2.2, .idle),
              ]),

        // ───────────── Stasiun ─────────────
        .init(id: "gambir", name: "Zetrum Stasiun Gambir", venue: .train,
              address: "Jl. Medan Merdeka Timur No. 1, Gambir",
              city: "Jakarta Pusat", lat: -6.17660, lon: 106.83060,
              open24: true, hours: "Buka 24 Jam", rating: 4.7, reviews: 405,
              facilities: [.toilet, .musholla, .minimarket, .cafe, .parking, .wifi, .atm, .lounge],
              units: [
                unit("gbr-1", "Star Charge", "Atlas 120", .ccs2, 120, .busy, fee: 57_000),
                unit("gbr-2", "Star Charge", "Nova 60", .ccs2, 60, .idle, fee: 25_000),
                unit("gbr-3", "Delta", "AC Max", .type2, 22, .idle),
                unit("gbr-4", "Delta", "AC Max", .type2, 22, .idle),
                unit("gbr-r2", "Zetrum", "R2 Motor", .shuko, 2.2, .idle),
              ]),

        .init(id: "halim", name: "Zetrum Stasiun Halim Whoosh", venue: .train,
              address: "Jl. DI Panjaitan, Halim Perdanakusuma, Makasar",
              city: "Jakarta Timur", lat: -6.24560, lon: 106.89280,
              open24: false, hours: "05.30 – 22.30", rating: 4.8, reviews: 512,
              facilities: [.toilet, .musholla, .minimarket, .cafe, .parking, .wifi, .lounge, .restaurant],
              units: [
                unit("hlm-1", "Sinexcel", "Ultra 200", .ccs2, 200, .idle, fee: 57_000),
                unit("hlm-2", "Sinexcel", "Ultra 200", .ccs2, 200, .idle, fee: 57_000),
                unit("hlm-3", "Delta", "AC Max", .type2, 22, .idle),
              ]),

        .init(id: "senen", name: "Zetrum Stasiun Pasar Senen", venue: .train,
              address: "Jl. Pasar Senen No. 14, Senen",
              city: "Jakarta Pusat", lat: -6.17440, lon: 106.84410,
              open24: true, hours: "Buka 24 Jam", rating: 4.1, reviews: 97,
              facilities: [.toilet, .musholla, .minimarket, .parking],
              units: [
                unit("snn-1", "Delta", "AC Max", .type2, 7.4, .idle),
                unit("snn-2", "ABB", "Terra 54", .ccs2, 50, .broken),
                unit("snn-r2", "Zetrum", "R2 Motor", .shuko, 2.2, .idle),
              ]),

        .init(id: "bogor", name: "Zetrum Stasiun Bogor", venue: .train,
              address: "Jl. Nyi Raja Permas No. 1, Cibogor, Bogor Tengah",
              city: "Kota Bogor", lat: -6.59510, lon: 106.79060,
              open24: true, hours: "Buka 24 Jam", rating: 4.4, reviews: 143,
              facilities: [.toilet, .musholla, .minimarket, .cafe, .parking],
              units: [
                unit("bgr-1", "Star Charge", "Nova 60", .ccs2, 60, .idle, fee: 25_000),
                unit("bgr-2", "Delta", "AC Max", .type2, 22, .busy),
                unit("bgr-r2", "Zetrum", "R2 Motor", .shuko, 2.2, .idle),
              ]),

        .init(id: "tanah-abang", name: "Zetrum Stasiun Tanah Abang", venue: .train,
              address: "Jl. Jati Baru Raya, Kampung Bali, Tanah Abang",
              city: "Jakarta Pusat", lat: -6.18520, lon: 106.81070,
              open24: true, hours: "Buka 24 Jam", rating: 4.0, reviews: 62,
              facilities: [.toilet, .musholla, .minimarket, .parking],
              units: [
                unit("tnb-1", "Delta", "AC Max", .type2, 11, .idle),
                unit("tnb-r2", "Zetrum", "R2 Motor", .shuko, 2.2, .idle),
              ]),

        // ───────────── Mal ─────────────
        .init(id: "grand-indonesia", name: "Zetrum Grand Indonesia", venue: .mall,
              address: "Jl. M.H. Thamrin No. 1, Menteng",
              city: "Jakarta Pusat", lat: -6.19520, lon: 106.82110,
              open24: false, hours: "10.00 – 22.00", rating: 4.8, reviews: 889,
              facilities: [.toilet, .musholla, .minimarket, .cafe, .parking, .wifi, .atm, .restaurant, .lounge],
              units: [
                unit("gi-1", "Star Charge", "Atlas 120", .ccs2, 120, .idle, fee: 57_000),
                unit("gi-2", "Star Charge", "Nova 60", .ccs2, 60, .busy, fee: 25_000),
                unit("gi-3", "Delta", "AC Max", .type2, 22, .idle),
                unit("gi-4", "Delta", "AC Max", .type2, 22, .idle),
                unit("gi-r2", "Zetrum", "R2 Motor", .shuko, 2.2, .idle),
              ]),

        .init(id: "plaza-senayan", name: "Zetrum Plaza Senayan", venue: .mall,
              address: "Jl. Asia Afrika No. 8, Gelora, Tanah Abang",
              city: "Jakarta Pusat", lat: -6.22550, lon: 106.79930,
              open24: false, hours: "10.00 – 22.00", rating: 4.7, reviews: 431,
              facilities: [.toilet, .musholla, .cafe, .parking, .wifi, .restaurant],
              units: [
                unit("ps-1", "ABB", "Terra 54", .ccs2, 50, .idle),
                unit("ps-2", "Delta", "AC Max", .type2, 22, .idle),
                unit("ps-3", "Delta", "AC Max", .type2, 22, .busy),
              ]),

        .init(id: "pim", name: "Zetrum Pondok Indah Mall 3", venue: .mall,
              address: "Jl. Metro Pondok Indah, Pondok Pinang, Kebayoran Lama",
              city: "Jakarta Selatan", lat: -6.26590, lon: 106.78380,
              open24: false, hours: "10.00 – 22.00", rating: 4.6, reviews: 376,
              facilities: [.toilet, .musholla, .minimarket, .cafe, .parking, .wifi, .atm, .restaurant],
              units: [
                unit("pim-1", "Star Charge", "Atlas 120", .ccs2, 120, .idle, fee: 57_000),
                unit("pim-2", "Delta", "AC Max", .type2, 22, .idle),
                unit("pim-r2", "Zetrum", "R2 Motor", .shuko, 2.2, .idle),
              ]),

        .init(id: "kelapa-gading", name: "Zetrum Mal Kelapa Gading", venue: .mall,
              address: "Jl. Bulevar Kelapa Gading Blok M, Kelapa Gading Barat",
              city: "Jakarta Utara", lat: -6.15750, lon: 106.90750,
              open24: false, hours: "10.00 – 22.00", rating: 4.5, reviews: 298,
              facilities: [.toilet, .musholla, .minimarket, .cafe, .parking, .wifi, .restaurant],
              units: [
                unit("mkg-1", "Star Charge", "Nova 60", .ccs2, 60, .idle, fee: 25_000),
                unit("mkg-2", "Delta", "AC Max", .type2, 11, .idle),
                unit("mkg-3", "Delta", "AC Max", .type2, 11, .broken),
                unit("mkg-r2", "Zetrum", "R2 Motor", .shuko, 2.2, .idle),
              ]),

        .init(id: "aeon-bsd", name: "Zetrum AEON Mall BSD City", venue: .mall,
              address: "Jl. BSD Raya Utama, Pagedangan, BSD City",
              city: "Kabupaten Tangerang", lat: -6.30590, lon: 106.64340,
              open24: false, hours: "10.00 – 22.00", rating: 4.7, reviews: 521,
              facilities: [.toilet, .musholla, .minimarket, .cafe, .parking, .wifi, .atm, .restaurant],
              units: [
                unit("aeon-1", "Sinexcel", "Ultra 200", .ccs2, 200, .idle, fee: 57_000),
                unit("aeon-2", "Star Charge", "Nova 60", .ccs2, 60, .idle, fee: 25_000),
                unit("aeon-3", "Delta", "AC Max", .type2, 22, .busy),
                unit("aeon-4", "Autel", "MaxiCharger AC", .type2, 11, .idle),
                unit("aeon-r2", "Zetrum", "R2 Motor", .shuko, 2.2, .idle),
              ]),

        .init(id: "summarecon-serpong", name: "Zetrum Summarecon Mall Serpong", venue: .mall,
              address: "Jl. Boulevard Gading Serpong, Pakulonan Barat, Kelapa Dua",
              city: "Kabupaten Tangerang", lat: -6.24230, lon: 106.62830,
              open24: false, hours: "10.00 – 22.00", rating: 4.6, reviews: 334,
              facilities: [.toilet, .musholla, .cafe, .parking, .wifi, .restaurant],
              units: [
                unit("sms-1", "Star Charge", "Nova 60", .ccs2, 60, .idle, fee: 25_000),
                unit("sms-2", "Delta", "AC Max", .type2, 22, .idle),
              ]),

        .init(id: "lippo-puri", name: "Zetrum Lippo Mall Puri", venue: .mall,
              address: "Jl. Puri Agung, Kembangan Selatan, Kembangan",
              city: "Jakarta Barat", lat: -6.18760, lon: 106.73780,
              open24: false, hours: "10.00 – 22.00", rating: 4.5, reviews: 211,
              facilities: [.toilet, .musholla, .cafe, .parking, .wifi, .restaurant],
              units: [
                unit("lpr-1", "ABB", "Terra 54", .ccs2, 50, .busy),
                unit("lpr-2", "Delta", "AC Max", .type2, 22, .idle),
              ]),

        // ───────────── Rest area & bandara ─────────────
        .init(id: "km57", name: "Zetrum Rest Area KM 57A", venue: .restArea,
              address: "Tol Jakarta–Cikampek KM 57A, Karawang Barat",
              city: "Kabupaten Karawang", lat: -6.32970, lon: 107.31440,
              open24: true, hours: "Buka 24 Jam", rating: 4.6, reviews: 1_208,
              facilities: [.toilet, .musholla, .minimarket, .cafe, .parking, .atm, .restaurant],
              units: [
                unit("km57-1", "Sinexcel", "Ultra 200", .ccs2, 200, .idle, fee: 57_000),
                unit("km57-2", "Sinexcel", "Ultra 200", .ccs2, 200, .busy, fee: 57_000),
                unit("km57-3", "Star Charge", "Atlas 120", .ccs2, 120, .idle, fee: 57_000),
                unit("km57-4", "ABB", "Terra 54", .chademo, 50, .idle),
                unit("km57-r2", "Zetrum", "R2 Motor", .shuko, 2.2, .idle),
              ]),

        .init(id: "km88b", name: "Zetrum Rest Area KM 88B", venue: .restArea,
              address: "Tol Purbaleunyi KM 88B, Purwakarta",
              city: "Kabupaten Purwakarta", lat: -6.67960, lon: 107.38990,
              open24: true, hours: "Buka 24 Jam", rating: 4.4, reviews: 642,
              facilities: [.toilet, .musholla, .minimarket, .cafe, .parking, .restaurant],
              units: [
                unit("km88-1", "Star Charge", "Atlas 120", .ccs2, 120, .idle, fee: 57_000),
                unit("km88-2", "Star Charge", "Nova 60", .ccs2, 60, .idle, fee: 25_000),
              ]),

        .init(id: "soetta-t3", name: "Zetrum Bandara Soekarno-Hatta T3", venue: .airport,
              address: "Terminal 3 Keberangkatan, Pajang, Benda",
              city: "Kota Tangerang", lat: -6.12560, lon: 106.65590,
              open24: true, hours: "Buka 24 Jam", rating: 4.8, reviews: 963,
              facilities: [.toilet, .musholla, .minimarket, .cafe, .parking, .wifi, .atm, .restaurant, .lounge],
              units: [
                unit("cgk-1", "Sinexcel", "Ultra 200", .ccs2, 200, .idle, fee: 57_000),
                unit("cgk-2", "Star Charge", "Atlas 120", .ccs2, 120, .idle, fee: 57_000),
                unit("cgk-3", "Star Charge", "Atlas 120", .ccs2, 120, .busy, fee: 57_000),
                unit("cgk-4", "Delta", "AC Max", .type2, 22, .idle),
                unit("cgk-5", "Delta", "AC Max", .type2, 22, .idle),
                unit("cgk-r2", "Zetrum", "R2 Motor", .shuko, 2.2, .idle),
              ]),

        // ───────────── Kantor & kampus ─────────────
        .init(id: "pln-trunojoyo", name: "Zetrum Kantor Pusat PLN", venue: .office,
              address: "Jl. Trunojoyo Blok M I/135, Melawai, Kebayoran Baru",
              city: "Jakarta Selatan", lat: -6.24030, lon: 106.79910,
              open24: false, hours: "07.00 – 19.00", rating: 4.5, reviews: 157,
              facilities: [.toilet, .musholla, .cafe, .parking, .wifi],
              units: [
                unit("pln-1", "Star Charge", "Atlas 120", .ccs2, 120, .idle, fee: 57_000),
                unit("pln-2", "Delta", "AC Max", .type2, 22, .idle),
                unit("pln-3", "Delta", "AC Max", .type2, 7.4, .idle),
              ]),

        .init(id: "ui-depok", name: "Zetrum Universitas Indonesia", venue: .campus,
              address: "Kampus UI Depok, Pondok Cina, Beji",
              city: "Kota Depok", lat: -6.36170, lon: 106.82720,
              open24: false, hours: "06.00 – 21.00", rating: 4.6, reviews: 184,
              facilities: [.toilet, .musholla, .minimarket, .cafe, .parking, .wifi],
              units: [
                unit("ui-1", "Star Charge", "Nova 60", .ccs2, 60, .idle, fee: 25_000),
                unit("ui-2", "Delta", "AC Max", .type2, 11, .idle),
                unit("ui-3", "Autel", "MaxiCharger AC", .type2, 11, .busy),
                unit("ui-r2", "Zetrum", "R2 Motor", .shuko, 2.2, .idle),
              ]),

        // ───────────── Rumah ─────────────
        .init(id: "home", name: "Zetrum Home Charging", venue: .office,
              address: "Wallbox terpasang di rumah sendiri",
              city: "Pengisian pribadi", lat: -6.26070, lon: 106.78180,
              open24: true, hours: "Buka 24 Jam", rating: 5.0, reviews: 1,
              facilities: [.parking, .wifi],
              units: [
                unit("home-1", "Wallbox", "Pulsar Plus", .type2, 7.4, .idle),
                unit("home-r2", "Zetrum", "R2 Motor", .shuko, 2.2, .idle),
              ]),
    ]

    static func place(_ id: String) -> Place? { places.first { $0.id == id } }

    static func unit(placeID: String, unitID: String) -> ChargerUnit? {
        place(placeID)?.units.first { $0.id == unitID }
    }

    /// Dicari dengan kode yang tertempel di badan charger.
    static func lookup(code: String) -> (Place, ChargerUnit)? {
        let needle = code.uppercased().replacingOccurrences(of: " ", with: "")
        for p in places {
            if let u = p.units.first(where: { $0.code == needle }) { return (p, u) }
        }
        return nil
    }

    /// Titik tengah peta saat pertama dibuka: Jakarta.
    static let defaultLat = -6.2088
    static let defaultLon = 106.8456
}
