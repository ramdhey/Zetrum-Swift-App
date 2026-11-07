import CoreImage
import CoreImage.CIFilterBuiltins
import MapKit
import SwiftUI

// MARK: - Ubin peta

/// Petanya OpenStreetMap, bukan peta bawaan Apple. Dua gaya: gelap (ubin
/// CARTO di atas data OSM, cocok dengan warna aplikasi) dan terang (ubin
/// resmi OSM). Keduanya wajib mencantumkan sumbernya di pojok peta.
enum TileStyle: String, CaseIterable, Identifiable {
    case dark, light
    var id: String { rawValue }

    var label: String { self == .dark ? "Gelap" : "Terang" }

    /// Sumbernya sama-sama ubin resmi OpenStreetMap. Yang membedakan cuma
    /// pewarnaannya, dan itu dikerjakan di perangkat.
    var template: String { "https://tile.openstreetmap.org/{z}/{x}/{y}.png" }

    var attribution: String { "© OpenStreetMap contributors" }
}

/// Dua hal dikerjakan di sini yang tidak bisa diserahkan ke MKTileOverlay
/// apa adanya:
///
/// 1. Aturan pakai ubin OSM mewajibkan User-Agent yang jelas, dan
///    MKTileOverlay tidak memberi jalan memasang header.
/// 2. OSM cuma punya gaya terang. Supaya peta tidak menyilaukan di tengah
///    aplikasi yang hampir hitam, ubinnya dibalik warnanya lalu diputar
///    rona 180° — cara lama yang bikin daratan jadi gelap, air tetap
///    kebiruan, dan tulisan jalan jadi terang, bukan sekadar diredupkan.
final class ZetrumTileOverlay: MKTileOverlay {
    private let dark: Bool

    private static let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.requestCachePolicy = .returnCacheDataElseLoad
        c.urlCache = URLCache(memoryCapacity: 16 << 20, diskCapacity: 160 << 20,
                              diskPath: "zetrum-tiles")
        return URLSession(configuration: c)
    }()

    /// Pembalikan warna harus dikerjakan di ruang sRGB, bukan ruang linear
    /// bawaan Core Image — di ruang linear, putih kertas peta cuma jadi abu
    /// sedang, bukan hitam.
    private static let ciContext = CIContext(options: [
        .useSoftwareRenderer: false,
        .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB) as Any,
    ])

    init(style: TileStyle) {
        dark = style == .dark
        super.init(urlTemplate: style.template)
        canReplaceMapContent = true
        tileSize = CGSize(width: 256, height: 256)
        minimumZ = 3
        maximumZ = 19
    }

    override func loadTile(at path: MKTileOverlayPath,
                           result: @escaping (Data?, (any Error)?) -> Void) {
        var req = URLRequest(url: url(forTilePath: path))
        req.setValue("ZetrumDemo/1.0 (aplikasi contoh pengisian EV; non-komersial)",
                     forHTTPHeaderField: "User-Agent")
        Self.session.dataTask(with: req) { [dark] data, _, err in
            guard dark, let data, let out = Self.darken(data) else {
                result(data, err); return
            }
            result(out, nil)
        }.resume()
    }

    private static func darken(_ data: Data) -> Data? {
        guard let src = CIImage(data: data) else { return nil }
        let inverted = src.applyingFilter("CIColorInvert")
        let rotated = inverted.applyingFilter("CIHueAdjust", parameters: [kCIInputAngleKey: Double.pi])
        // sedikit diredam supaya tidak terlalu kontras di balik kartu gelap
        let muted = rotated.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.58, kCIInputBrightnessKey: 0.05, kCIInputContrastKey: 0.94])
        guard let cg = ciContext.createCGImage(muted, from: src.extent) else { return nil }
        return UIImage(cgImage: cg).pngData()
    }
}

// MARK: - Marker

final class PlacePin: NSObject, MKAnnotation {
    let place: Place
    var coordinate: CLLocationCoordinate2D { .init(latitude: place.lat, longitude: place.lon) }
    var title: String? { place.name }
    var subtitle: String? { "\(place.available)/\(place.totalUnits) konektor tersedia" }
    init(_ p: Place) { place = p }
}

/// Penanda digambar sendiri: keping gelap dengan garis setrum, lambang
/// jenis tempatnya di dalam, dan titik kecil yang warnanya ikut ketersediaan.
private func pinImage(for place: Place, selected: Bool) -> UIImage {
    let w: CGFloat = selected ? 46 : 38
    let h: CGFloat = w + 9
    let r = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
    let volt = UIColor(red: 0.765, green: 0.961, blue: 0.235, alpha: 1)
    let ion  = UIColor(red: 0.435, green: 0.890, blue: 1.000, alpha: 1)
    let alarm = UIColor(red: 1.000, green: 0.420, blue: 0.353, alpha: 1)
    let void = UIColor(red: 0.039, green: 0.043, blue: 0.051, alpha: 1)

    let ring: UIColor = place.available == 0 ? alarm : (place.hasDC ? volt : ion)

    return r.image { ctx in
        let c = ctx.cgContext
        let box = CGRect(x: 1.5, y: 1.5, width: w - 3, height: w - 3)
        // ekor penanda
        let tail = UIBezierPath()
        tail.move(to: CGPoint(x: w / 2 - 6, y: w - 4))
        tail.addLine(to: CGPoint(x: w / 2, y: h - 2))
        tail.addLine(to: CGPoint(x: w / 2 + 6, y: w - 4))
        tail.close()
        ring.setFill(); tail.fill()

        let body = UIBezierPath(roundedRect: box, cornerRadius: box.width * 0.33)
        void.withAlphaComponent(0.96).setFill(); body.fill()
        ring.setStroke(); body.lineWidth = selected ? 2.6 : 1.8; body.stroke()

        let cfg = UIImage.SymbolConfiguration(pointSize: w * 0.40, weight: .bold)
        if let sym = UIImage(systemName: place.venue.symbol, withConfiguration: cfg)?
            .withTintColor(ring, renderingMode: .alwaysOriginal) {
            sym.draw(in: CGRect(x: (w - sym.size.width) / 2,
                                y: (w - sym.size.height) / 2 - 1,
                                width: sym.size.width, height: sym.size.height))
        }
        // titik ketersediaan
        let dot = CGRect(x: w - 13, y: 2, width: 9, height: 9)
        void.setFill(); c.fillEllipse(in: dot.insetBy(dx: -1.6, dy: -1.6))
        (place.available == 0 ? alarm : volt).setFill(); c.fillEllipse(in: dot)
    }
}

// MARK: - Peta

struct OSMMapView: UIViewRepresentable {
    var places: [Place]
    var style: TileStyle
    @Binding var selectedID: String?
    /// Naikkan angkanya untuk memaksa peta kembali ke posisi awal.
    var recenterToken: Int
    var onSelect: (Place) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.pointOfInterestFilter = .excludingAll
        map.showsCompass = false
        map.showsScale = false
        map.showsUserLocation = true
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.register(MKAnnotationView.self,
                     forAnnotationViewWithReuseIdentifier: "pin")
        context.coordinator.applyTiles(style, to: map)
        map.setRegion(MKCoordinateRegion(
            center: .init(latitude: Zetrum.defaultLat, longitude: Zetrum.defaultLon),
            span: .init(latitudeDelta: 0.42, longitudeDelta: 0.42)), animated: false)
        map.addAnnotations(places.map(PlacePin.init))
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        let co = context.coordinator
        co.parent = self

        if co.style != style {
            co.style = style
            co.applyTiles(style, to: map)
        }

        let wanted = Set(places.map(\.id))
        let shown = Set(map.annotations.compactMap { ($0 as? PlacePin)?.place.id })
        if wanted != shown {
            map.removeAnnotations(map.annotations.filter { $0 is PlacePin })
            map.addAnnotations(places.map(PlacePin.init))
        }
        for a in map.annotations.compactMap({ $0 as? PlacePin }) {
            map.view(for: a)?.image = pinImage(for: a.place, selected: a.place.id == selectedID)
            map.view(for: a)?.zPriority = a.place.id == selectedID ? .max : .defaultUnselected
        }

        if let id = selectedID, co.centredOn != id,
           let p = places.first(where: { $0.id == id }) {
            co.centredOn = id
            let span = map.region.span.latitudeDelta > 0.09
                ? MKCoordinateSpan(latitudeDelta: 0.045, longitudeDelta: 0.045)
                : map.region.span
            map.setRegion(MKCoordinateRegion(
                center: .init(latitude: p.lat - span.latitudeDelta * 0.22, longitude: p.lon),
                span: span), animated: true)
        }
        if selectedID == nil { co.centredOn = nil }

        if co.recenterToken != recenterToken {
            co.recenterToken = recenterToken
            map.setRegion(MKCoordinateRegion(
                center: map.userLocation.location?.coordinate
                    ?? .init(latitude: Zetrum.defaultLat, longitude: Zetrum.defaultLon),
                span: .init(latitudeDelta: 0.12, longitudeDelta: 0.12)), animated: true)
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: OSMMapView
        var style: TileStyle
        var centredOn: String?
        var recenterToken: Int
        private var overlay: MKTileOverlay?

        init(_ p: OSMMapView) {
            parent = p
            style = p.style
            recenterToken = p.recenterToken
        }

        func applyTiles(_ style: TileStyle, to map: MKMapView) {
            if let old = overlay { map.removeOverlay(old) }
            let o = ZetrumTileOverlay(style: style)
            overlay = o
            map.addOverlay(o, level: .aboveLabels)
        }

        func mapView(_ map: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let t = overlay as? MKTileOverlay else { return MKOverlayRenderer(overlay: overlay) }
            return MKTileOverlayRenderer(tileOverlay: t)
        }

        func mapView(_ map: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            guard let pin = annotation as? PlacePin else { return nil }
            let v = map.dequeueReusableAnnotationView(withIdentifier: "pin", for: annotation)
            v.annotation = annotation
            v.image = pinImage(for: pin.place, selected: pin.place.id == parent.selectedID)
            v.centerOffset = CGPoint(x: 0, y: -(v.image?.size.height ?? 40) / 2)
            v.canShowCallout = false
            return v
        }

        func mapView(_ map: MKMapView, didSelect view: MKAnnotationView) {
            guard let pin = view.annotation as? PlacePin else { return }
            map.deselectAnnotation(view.annotation, animated: false)
            centredOn = pin.place.id
            parent.onSelect(pin.place)
        }
    }
}
