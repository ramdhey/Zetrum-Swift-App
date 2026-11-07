import Foundation

enum VehicleKind: String, Codable, Hashable, CaseIterable, Identifiable {
    case car, bike
    var id: String { rawValue }
    var label: String { self == .car ? T("kind.car") : T("kind.bike") }
    var plural: String { self == .car ? T("kind.cars") : T("kind.bikes") }
    var symbol: String { self == .car ? "car.fill" : "scooter" }
}

/// Satu model kendaraan listrik yang dijual di Indonesia.
///
/// Angka baterai dan daya di sini dipakai langsung untuk menghitung biaya,
/// jadi sedapat mungkin diambil dari spesifikasi pabrikan. `photo` diisi
/// nama aset kalau ada fotonya; kalau nil, yang digambar siluetnya.
struct Vehicle: Codable, Hashable, Identifiable {
    var id: String
    var brand: String
    var model: String
    var variant: String?
    var kind: VehicleKind
    var style: VehicleArt.Form
    /// Kapasitas baterai yang bisa dipakai, kWh.
    var batteryKWh: Double
    /// Daya terbesar yang sanggup diterima lewat soket AC.
    var acMaxKW: Double
    /// Daya terbesar lewat soket DC. Nol artinya tidak bisa isi cepat.
    var dcMaxKW: Double
    var acPort: Connector
    var dcPort: Connector?
    /// Jarak tempuh klaim pabrikan, km.
    var rangeKm: Int
    var photo: String?

    var name: String { "\(brand) \(model)" }

    var ports: [Connector] { [acPort] + (dcPort.map { [$0] } ?? []) }

    /// Bisa dicolok ke kotak ini atau tidak.
    func accepts(_ unit: ChargerUnit) -> Bool {
        unit.connector == acPort || (dcPort != nil && unit.connector == dcPort!)
    }

    /// Daya yang betul-betul mengalir: yang terkecil antara charger dan mobil.
    func effectiveKW(on unit: ChargerUnit) -> Double {
        unit.connector.isDC ? min(unit.kW, dcMaxKW) : min(unit.kW, acMaxKW)
    }

    /// Berapa km bertambah per kWh yang masuk.
    var kmPerKwh: Double { batteryKWh > 0 ? Double(rangeKm) / batteryKWh : 0 }
}

extension Vehicle {
    var displayName: String {
        guard let v = variant, !v.isEmpty else { return name }
        return "\(name) \(v)"
    }
}
