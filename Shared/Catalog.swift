import Foundation

/// Katalog kendaraan listrik yang dijual resmi di Indonesia.
///
/// Kapasitas baterai memakai angka kotor (nominal) dari pabrikan — tidak
/// ada satu pun sumber Indonesia yang menerbitkan kapasitas bersih, jadi
/// lebih jujur konsisten pakai angka kotor daripada mencampur keduanya.
///
/// Daya pengisian mobil memakai spesifikasi global pabrikan kalau versi
/// Indonesia tidak menerbitkannya. Untuk motor, daya charger dihitung dari
/// waktu pengisian penuh yang diumumkan pabrikannya — jadi anggap angka
/// motor sebagai perkiraan, bukan kutipan.
///
/// Yang sengaja tidak dimasukkan: Tesla (tidak ada agen resmi, hanya impor
/// umum), Yamaha E01 dan NEO's (tidak pernah dijual di sini), dan Yamaha
/// Fazzio Hybrid — itu motor bensin dengan bantuan start listrik, bukan EV.
enum Catalog {

    private static func car(_ id: String, _ brand: String, _ model: String, _ variant: String?,
                            _ style: VehicleArt.Form, _ kWh: Double, _ ac: Double, _ dc: Double,
                            _ km: Int, dcPort: Connector = .ccs2) -> Vehicle {
        .init(id: id, brand: brand, model: model, variant: variant, kind: .car, style: style,
              batteryKWh: kWh, acMaxKW: ac, dcMaxKW: dc,
              acPort: .type2, dcPort: dc > 0 ? dcPort : nil,
              rangeKm: km, photo: "veh-" + id)
    }

    private static func bike(_ id: String, _ brand: String, _ model: String, _ variant: String?,
                             _ style: VehicleArt.Form, _ kWh: Double, _ ac: Double,
                             _ km: Int) -> Vehicle {
        .init(id: id, brand: brand, model: model, variant: variant, kind: .bike, style: style,
              batteryKWh: kWh, acMaxKW: ac, dcMaxKW: 0,
              acPort: .shuko, dcPort: nil, rangeKm: km, photo: "veh-" + id)
    }

    // MARK: Mobil

    static let cars: [Vehicle] = [
        car("wuling-air-lite",   "Wuling", "Air ev", "Lite",            .hatchback, 17.30, 2.0,  0,   200),
        car("wuling-air-lr",     "Wuling", "Air ev", "Long Range",      .hatchback, 26.70, 6.6,  0,   300),
        car("wuling-binguo-lr",  "Wuling", "BinguoEV", "Long Range",    .hatchback, 31.90, 7.7,  38,  333, dcPort: .gbt),
        car("wuling-binguo-pr",  "Wuling", "BinguoEV", "Premium Range", .hatchback, 37.90, 7.7,  38,  410, dcPort: .gbt),
        car("wuling-cloud",      "Wuling", "Cloud EV", nil,             .mpv,       50.60, 7.0,  60,  460, dcPort: .gbt),

        car("hyundai-ioniq5-sr", "Hyundai", "Ioniq 5", "Standard Range", .suv,      58.00, 10.5, 175, 384),
        car("hyundai-ioniq5-lr", "Hyundai", "Ioniq 5", "Long Range",     .suv,      72.60, 10.5, 233, 481),
        car("hyundai-ioniq6",    "Hyundai", "Ioniq 6", "Signature AWD",  .sedan,    77.40, 10.5, 233, 519),
        car("hyundai-kona-sr",   "Hyundai", "Kona Electric", "Standard Range", .suv, 48.90, 10.5, 74, 448),
        car("hyundai-kona-lr",   "Hyundai", "Kona Electric", "Long Range",     .suv, 66.00, 10.5, 102, 549),

        car("kia-ev6",           "Kia", "EV6", "GT-Line",               .suv,       77.40, 11.0, 233, 506),
        car("kia-ev9",           "Kia", "EV9", "GT-Line",               .suv,       99.80, 11.0, 210, 497),

        car("byd-atto1",         "BYD", "Atto 1", "Premium",            .hatchback, 38.88, 6.6,  40,  380),
        car("byd-dolphin-dyn",   "BYD", "Dolphin", "Dynamic",           .hatchback, 44.90, 11.0, 60,  410),
        car("byd-dolphin-prem",  "BYD", "Dolphin", "Premium",           .hatchback, 60.48, 11.0, 80,  490),
        car("byd-atto3-adv",     "BYD", "Atto 3", "Advanced",           .suv,       49.92, 7.0,  70,  410),
        car("byd-atto3-sup",     "BYD", "Atto 3", "Superior",           .suv,       60.48, 7.0,  88,  480),
        car("byd-seal-prem",     "BYD", "Seal", "Premium RWD",          .sedan,     82.56, 7.0,  150, 650),
        car("byd-seal-perf",     "BYD", "Seal", "Performance AWD",      .sedan,     82.56, 7.0,  150, 580),
        car("byd-m6-std",        "BYD", "M6", "Standard",               .mpv,       55.40, 7.0,  89,  420),
        car("byd-m6-sup",        "BYD", "M6", "Superior",               .mpv,       71.80, 7.0,  115, 530),
        car("byd-sealion7",      "BYD", "Sealion 7", "Premium",         .suv,       82.56, 11.0, 150, 567),
        car("denza-d9",          "Denza", "D9", "EV",                   .mpv,      103.36, 11.0, 166, 600),

        car("chery-omoda-e5",    "Chery", "Omoda E5", nil,              .suv,       61.00, 9.9,  80,  430),
        car("chery-j6-rwd",      "Chery", "J6", "RWD",                  .suv,       65.70, 7.0,  100, 426),
        car("chery-j6-awd",      "Chery", "J6", "iWD AWD",              .suv,       69.80, 7.0,  100, 418),
        car("jaecoo-j5-ev",      "Jaecoo", "J5 EV", nil,                .suv,       60.90, 11.0, 130, 461),

        car("neta-v2",           "Neta", "V-II", nil,                   .hatchback, 40.70, 6.6,  50,  401),
        car("neta-x",            "Neta", "X", "500 Elite",              .suv,       63.56, 6.6,  105, 480),

        car("mg4-magnify",       "MG", "MG4 EV", "Magnify",             .hatchback, 51.00, 6.6,  117, 425),
        car("mg4-max",           "MG", "MG4 EV", "Magnify Max",         .hatchback, 64.00, 7.0,  144, 540),
        car("mg-zs-ev",          "MG", "ZS EV", "Magnify",              .suv,       50.30, 6.6,  76,  403),
        car("maxus-mifa9",       "Maxus", "Mifa 9", nil,                .mpv,       90.00, 11.0, 130, 435),

        car("mini-cooper-se",    "MINI", "Cooper SE", nil,              .hatchback, 54.20, 11.0, 95,  402),
        car("toyota-bz4x",       "Toyota", "bZ4X", nil,                 .suv,       71.40, 6.6,  150, 500),
        car("lexus-ux300e",      "Lexus", "UX 300e", nil,               .suv,       54.35, 6.6,  50,  300, dcPort: .chademo),
        car("nissan-leaf",       "Nissan", "Leaf", nil,                 .hatchback, 40.00, 6.6,  50,  311, dcPort: .chademo),
        car("mitsubishi-l100ev", "Mitsubishi", "L100 EV", nil,          .van,       20.00, 3.0,  0,   180),

        car("dfsk-gelora-e",     "DFSK", "Gelora E", nil,               .van,       42.00, 6.6,  60,  300, dcPort: .gbt),
        car("citroen-ec3",       "Citroën", "ë-C3", nil,                .hatchback, 29.20, 3.3,  30,  320),

        car("vinfast-vf5",       "VinFast", "VF 5", nil,                .suv,       29.60, 7.4,  60,  260),
        car("vinfast-vf7-eco",   "VinFast", "VF 7", "Eco",              .suv,       59.60, 11.0, 100, 430),
        car("vinfast-vfe34",     "VinFast", "VF e34", nil,              .suv,       41.90, 7.4,  40,  318),

        car("aion-yplus-ex",     "GAC Aion", "Y Plus", "Exclusive",     .suv,       50.66, 6.6,  70,  410),
        car("aion-yplus-prem",   "GAC Aion", "Y Plus", "Premium",       .suv,       63.20, 6.6,  70,  490),
        car("aion-es",           "GAC Aion", "ES", nil,                 .sedan,     55.20, 6.6,  70,  442),

        car("honda-en1",         "Honda", "e:N1", nil,                  .suv,       68.80, 11.0, 78,  500),
        car("seres-e1",          "Seres", "E1", "Type L",               .hatchback, 16.80, 3.3,  0,   220),

        car("geely-ex5",         "Geely", "EX5", "Pro",                 .suv,       60.22, 11.0, 100, 495),
        car("xpeng-g6",          "XPeng", "G6", "Pro",                  .suv,       87.50, 11.0, 215, 525),
        car("aletra-l8s",        "Aletra", "L8s", "Long Range",         .mpv,       64.74, 6.6,  60,  540),

        car("bmw-ix1",           "BMW", "iX1", "eDrive20",              .suv,       64.78, 11.0, 130, 474),
        car("bmw-i5",            "BMW", "i5", "eDrive40",               .sedan,     81.20, 11.0, 205, 497),
        car("bmw-i7",            "BMW", "i7", "xDrive60",               .sedan,    101.70, 11.0, 195, 625),
        car("mercedes-eqa",      "Mercedes-Benz", "EQA", "250",         .suv,       66.50, 11.0, 100, 496),
        car("mercedes-eqe",      "Mercedes-Benz", "EQE", "350+",        .sedan,     90.60, 11.0, 170, 639),
        car("mercedes-eqs",      "Mercedes-Benz", "EQS", "450+",        .sedan,    107.80, 11.0, 200, 696),
    ]

    // MARK: Motor

    static let bikes: [Vehicle] = [
        bike("gesits-g1",        "Gesits", "G1", "2 baterai",       .scooter,     2.88, 0.50, 100),
        bike("gesits-raya-g",    "Gesits", "Raya G", nil,           .scooter,     1.44, 0.50, 60),
        bike("alva-one",         "Alva", "One", nil,                .scooter,     2.70, 1.06, 70),
        bike("alva-cervo",       "Alva", "Cervo", "2 baterai",      .scooter,     3.54, 1.06, 125),
        bike("polytron-fox500",  "Polytron", "Fox 500", nil,        .scooter,     3.89, 0.85, 130),
        bike("polytron-foxr",    "Polytron", "Fox-R", nil,          .scooter,     3.70, 0.82, 130),
        bike("polytron-foxs",    "Polytron", "Fox-S", nil,          .scooter,     1.94, 0.40, 70),
        bike("volta-401",        "Volta", "401", nil,               .scooter,     1.38, 0.20, 60),
        bike("volta-mandala",    "Volta", "Mandala", nil,           .scooter,     1.34, 0.20, 60),
        bike("united-tx3000",    "United", "TX3000", "2 baterai",   .scooter,     3.36, 0.40, 120),
        bike("united-c2000",     "United", "C2000", "2 baterai",    .scooter,     3.74, 0.40, 185),
        bike("smoot-tempur",     "Smoot", "Tempur", nil,            .scooter,     1.44, 0.30, 70),
        bike("smoot-zuzu",       "Smoot", "Zuzu", nil,              .scooter,     1.38, 0.30, 60),
        bike("selis-emax-li",    "Selis", "E-Max", "Lithium",       .scooter,     1.50, 0.25, 60),
        bike("selis-emax-lr",    "Selis", "E-Max", "Long Range",    .scooter,     4.20, 0.60, 230),
        bike("viar-q1",          "Viar", "New Q1", nil,             .scooter,     1.38, 0.30, 60),
        bike("davigo-dragon-sli","Davigo", "Dragon-SLi", nil,       .scooter,     3.74, 0.50, 200),
        bike("rakata-s9",        "Rakata", "S9", nil,               .scooter,     1.20, 0.20, 55),
        bike("exotic-sterrato",  "Exotic", "Sterrato", nil,         .scooter,     1.21, 0.20, 55),
        bike("greentech-vp",     "Greentech", "VP", nil,            .scooter,     2.30, 0.40, 100),
        bike("honda-em1",        "Honda", "EM1 e:", nil,            .scooter,     1.31, 0.27, 41),
        bike("honda-icon-e",     "Honda", "ICON e:", nil,           .scooter,     1.47, 0.27, 53),
        bike("honda-cuv-e",      "Honda", "CUV e:", nil,            .scooter,     2.63, 0.54, 80),
        bike("electrum-h3",      "Electrum", "H3", nil,             .scooter,     1.80, 0.40, 70),
        bike("electrum-h5",      "Electrum", "H5", "Performance",   .scooter,     3.60, 0.40, 120),
        bike("charged-anoa",     "Charged", "Anoa", nil,            .scooter,     2.70, 0.60, 100),
        bike("charged-maleo",    "Charged", "Maleo", nil,           .scooter,     2.70, 0.60, 120),
        bike("charged-rimau",    "Charged", "Rimau", nil,           .motorcycle,  2.70, 0.60, 110),
        bike("charged-baycat",   "Charged", "Baycat", "2 baterai",  .scooter,     4.40, 0.90, 170),
        bike("maka-cavalry",     "Maka Motors", "Cavalry", nil,     .motorcycle,  4.00, 0.65, 160),
    ]

    static let all: [Vehicle] = cars + bikes

    static func vehicle(_ id: String) -> Vehicle? { all.first { $0.id == id } }

    static func list(_ kind: VehicleKind) -> [Vehicle] { kind == .car ? cars : bikes }

    /// Dikelompokkan per merek, merek diurutkan abjad.
    static func byBrand(_ kind: VehicleKind, search: String = "") -> [(String, [Vehicle])] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        let pool = list(kind).filter {
            q.isEmpty || $0.displayName.lowercased().contains(q)
        }
        return Dictionary(grouping: pool, by: \.brand)
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
            .map { ($0.key, $0.value) }
    }

    static let fallback = cars.first { $0.id == "hyundai-ioniq5-lr" } ?? cars[0]
}
