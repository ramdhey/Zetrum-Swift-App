import Foundation

// MARK: - Soket

/// Soket yang betulan dipakai di Indonesia. Motor listrik umumnya tidak
/// punya soket mobil sama sekali — dia colok ke stopkontak biasa atau
/// baterainya ditukar.
enum Connector: String, Codable, Hashable, CaseIterable, Identifiable {
    case type2      // AC Type 2 (Mennekes) — hampir semua mobil
    case ccs2       // DC CCS2 — pengisian cepat
    case chademo    // DC CHAdeMO — Nissan, beberapa Mitsubishi
    case gbt        // DC GB/T — sebagian mobil Cina
    case shuko      // AC Schuko 3 pin — charger bawaan motor
    case swap       // Tukar baterai, bukan diisi

    var id: String { rawValue }

    var label: String {
        switch self {
        case .type2:   "AC Type 2"
        case .ccs2:    "DC CCS2"
        case .chademo: "DC CHAdeMO"
        case .gbt:     "DC GB/T"
        case .shuko:   "AC Schuko"
        case .swap:    T("connector.swap")
        }
    }

    var short: String {
        switch self {
        case .type2, .shuko: "AC"
        case .ccs2, .chademo, .gbt: "DC"
        case .swap: "SWAP"
        }
    }

    var isDC: Bool { self == .ccs2 || self == .chademo || self == .gbt }

    /// Gambar soketnya, bukan ikon generik.
    var glyph: SocketGlyph.Kind {
        switch self {
        case .type2:   .type2
        case .ccs2:    .ccs2
        case .chademo: .chademo
        case .gbt:     .gbt
        case .shuko:   .shuko
        case .swap:    .swap
        }
    }
}

// MARK: - Keadaan satu kotak pengisian

enum UnitStatus: String, Codable, Hashable {
    case idle        // nganggur, bisa dipakai
    case busy        // sedang dipakai orang
    case broken      // rusak / dalam perbaikan

    var label: String {
        switch self {
        case .idle:   T("status.idle")
        case .busy:   T("status.busy")
        case .broken: T("status.broken")
        }
    }
    var usable: Bool { self == .idle }
}

/// Satu kotak pengisian. Satu lokasi bisa punya beberapa, merek dan
/// dayanya beda-beda — persis seperti di SPKLU sungguhan.
struct ChargerUnit: Codable, Hashable, Identifiable {
    var id: String
    var maker: String          // "Delta", "Star Charge", "ABB"
    var model: String          // "AC Max", "Nova 60"
    var connector: Connector
    var kW: Double
    var ratePerKwh: Double     // rupiah per kWh
    var serviceFee: Int        // biaya layanan sekali pakai
    var status: UnitStatus

    var title: String { "\(maker) \(model)" }

    /// Kode yang tertempel di badan charger, yang dipindai sebelum mengisi.
    var code: String { "ZTR-" + id.uppercased().replacingOccurrences(of: "-", with: "") }

    var powerLabel: String { Daya.kw(kW) + " kW" }
    var headline: String { "\(connector.label) · \(powerLabel)" }

    /// Pengisian cepat melandai jauh lebih tajam di atas 80% daripada AC.
    var taperFloor: Double {
        switch kW {
        case ..<11:   0.70
        case ..<30:   0.55
        case ..<70:   0.26
        case ..<130:  0.18
        default:      0.13
        }
    }
}

// MARK: - Jenis tempat

enum Venue: String, Codable, Hashable, CaseIterable, Identifiable {
    case hospital, stadium, train, mall, restArea, airport, office, campus

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hospital: T("venue.hospital")
        case .stadium:  T("venue.stadium")
        case .train:    T("venue.train")
        case .mall:     T("venue.mall")
        case .restArea: T("venue.restArea")
        case .airport:  T("venue.airport")
        case .office:   T("venue.office")
        case .campus:   T("venue.campus")
        }
    }

    var symbol: String {
        switch self {
        case .hospital: "cross.case.fill"
        case .stadium:  "sportscourt.fill"
        case .train:    "tram.fill"
        case .mall:     "bag.fill"
        case .restArea: "road.lanes"
        case .airport:  "airplane"
        case .office:   "building.2.fill"
        case .campus:   "graduationcap.fill"
        }
    }
}

enum Facility: String, Codable, Hashable, CaseIterable, Identifiable {
    case toilet, musholla, minimarket, cafe, parking, wifi, atm, restaurant, lounge

    var id: String { rawValue }

    var label: String {
        switch self {
        case .toilet:     T("facility.toilet")
        case .musholla:   T("facility.musholla")
        case .minimarket: T("facility.minimarket")
        case .cafe:       T("facility.cafe")
        case .parking:    T("facility.parking")
        case .wifi:       T("facility.wifi")
        case .atm:        T("facility.atm")
        case .restaurant: T("facility.restaurant")
        case .lounge:     T("facility.lounge")
        }
    }

    var symbol: String {
        switch self {
        case .toilet:     "toilet.fill"
        case .musholla:   "moon.stars.fill"
        case .minimarket: "cart.fill"
        case .cafe:       "cup.and.saucer.fill"
        case .parking:    "parkingsign"
        case .wifi:       "wifi"
        case .atm:        "banknote.fill"
        case .restaurant: "fork.knife"
        case .lounge:     "sofa.fill"
        }
    }
}

// MARK: - Lokasi SPKLU

struct Place: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var venue: Venue
    var address: String
    var city: String
    var lat: Double
    var lon: Double
    var open24: Bool
    var hours: String
    var rating: Double
    var reviews: Int
    var facilities: [Facility]
    var units: [ChargerUnit]

    var available: Int { units.filter(\.usableNow).count }
    var totalUnits: Int { units.count }

    /// Daya tertinggi yang ada di lokasi ini — dipakai sebagai lencana di peta.
    var peakKW: Double { units.map(\.kW).max() ?? 0 }
    var hasDC: Bool { units.contains { $0.connector.isDC } }

    /// Jam bukanya disimpan apa adanya, tapi yang ditampilkan ikut bahasa:
    /// Indonesia menulis `10.00 – 22.00`, Inggris `10:00 – 22:00`.
    var hoursLabel: String {
        if open24 { return T("place.open24") }
        return Loc.lang == .english
            ? hours.replacingOccurrences(of: ".", with: ":")
            : hours
    }

    var tariffRange: String {
        let rates = Set(units.map(\.ratePerKwh)).sorted()
        guard let lo = rates.first, let hi = rates.last else { return "—" }
        return lo == hi ? Rupiah.decimal(lo) + "/kWh"
                        : "\(Rupiah.decimal(lo))–\(Rupiah.decimal(hi))/kWh"
    }

    func distance(from lat0: Double, _ lon0: Double) -> Double {
        let r = 6371.0
        let dLat = (lat - lat0) * .pi / 180
        let dLon = (lon - lon0) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat0 * .pi / 180) * cos(lat * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        return r * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

extension ChargerUnit {
    var usableNow: Bool { status.usable }
}
