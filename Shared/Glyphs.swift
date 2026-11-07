import SwiftUI
import UIKit

// MARK: - Gambar soket

/// Soketnya digambar sesuai bentuk aslinya — Type 2 pipih di atas, CCS2
/// punya dua pin gemuk di bawahnya, CHAdeMO bundar penuh. Di aplikasi
/// pengisian, ikon colokan generik bikin orang salah ambil kabel.
struct SocketGlyph: View {
    enum Kind { case type2, ccs2, chademo, gbt, shuko, swap }

    var kind: Kind
    var size: CGFloat = 26
    var tint: Color = Pal.ink

    var body: some View {
        Canvas { ctx, s in
            let u = min(s.width, s.height)
            let o = CGPoint(x: (s.width - u) / 2, y: (s.height - u) / 2)
            func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: o.x + x * u, y: o.y + y * u)
            }
            func pin(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
                let c = P(x, y)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r * u, y: c.y - r * u,
                                                width: r * 2 * u, height: r * 2 * u)),
                         with: .color(tint))
            }
            let line = GraphicsContext.Shading.color(tint)
            let stroke = StrokeStyle(lineWidth: u * 0.07, lineCap: .round, lineJoin: .round)

            switch kind {
            case .type2, .ccs2, .chademo, .gbt:
                // Badan soket. Type 2 dan CCS2 punya sisi atas yang dipapas
                // rata; CHAdeMO dan GB/T bundar penuh.
                let top: CGRect = kind == .ccs2
                    ? CGRect(x: o.x + 0.13 * u, y: o.y + 0.04 * u, width: 0.74 * u, height: 0.56 * u)
                    : CGRect(x: o.x + 0.07 * u, y: o.y + 0.07 * u, width: 0.86 * u, height: 0.86 * u)
                ctx.stroke(shell(in: top, flatTop: kind != .chademo && kind != .gbt),
                           with: line, style: stroke)

                /// Titik dalam koordinat badan soket, bukan seluruh kotak.
                func inPin(_ fx: CGFloat, _ fy: CGFloat, _ fr: CGFloat) {
                    let c = CGPoint(x: top.minX + fx * top.width, y: top.minY + fy * top.height)
                    let r = fr * min(top.width, top.height)
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r,
                                                    width: r * 2, height: r * 2)),
                             with: .color(tint))
                }

                switch kind {
                case .chademo:
                    inPin(0.31, 0.35, 0.115); inPin(0.69, 0.35, 0.115)
                    inPin(0.28, 0.70, 0.058); inPin(0.50, 0.78, 0.058); inPin(0.72, 0.70, 0.058)
                case .gbt:
                    inPin(0.50, 0.22, 0.090)
                    inPin(0.24, 0.50, 0.075); inPin(0.76, 0.50, 0.075)
                    inPin(0.36, 0.78, 0.075); inPin(0.64, 0.78, 0.075)
                default:
                    // Type 2. Di badan penuh pinnya digambar lengkap; di
                    // kepala CCS2 yang kecil cuma tiga, supaya tetap kebaca
                    // waktu ikonnya cuma 26 poin.
                    if kind == .ccs2 {
                        inPin(0.30, 0.42, 0.105); inPin(0.70, 0.42, 0.105)
                        inPin(0.50, 0.72, 0.105)
                    } else {
                        inPin(0.37, 0.25, 0.050); inPin(0.63, 0.25, 0.050)
                        inPin(0.25, 0.49, 0.088); inPin(0.50, 0.43, 0.088); inPin(0.75, 0.49, 0.088)
                        inPin(0.35, 0.73, 0.088); inPin(0.65, 0.73, 0.088)
                    }
                }

                if kind == .ccs2 {             // dua pin DC gemuk di bawah
                    let low = CGRect(x: o.x + 0.25 * u, y: o.y + 0.62 * u,
                                     width: 0.50 * u, height: 0.33 * u)
                    ctx.stroke(shell(in: low, flatTop: true), with: line, style: stroke)
                    let r = 0.105 * u
                    for cx in [low.midX - 0.112 * u, low.midX + 0.112 * u] {
                        ctx.fill(Path(ellipseIn: CGRect(x: cx - r, y: low.midY + 0.012 * u - r,
                                                        width: r * 2, height: r * 2)),
                                 with: .color(tint))
                    }
                }

            case .shuko:
                ctx.stroke(Path(ellipseIn: CGRect(x: o.x + 0.08 * u, y: o.y + 0.08 * u,
                                                  width: 0.84 * u, height: 0.84 * u)),
                           with: line, style: stroke)
                pin(0.34, 0.50, 0.095); pin(0.66, 0.50, 0.095)
                var clip = Path()
                clip.move(to: P(0.30, 0.13)); clip.addLine(to: P(0.70, 0.13))
                clip.move(to: P(0.30, 0.87)); clip.addLine(to: P(0.70, 0.87))
                ctx.stroke(clip, with: line, style: stroke)

            case .swap:
                var box = Path(roundedRect: CGRect(x: o.x + 0.14 * u, y: o.y + 0.20 * u,
                                                   width: 0.62 * u, height: 0.60 * u),
                               cornerRadius: u * 0.10)
                ctx.stroke(box, with: line, style: stroke)
                box = Path(roundedRect: CGRect(x: o.x + 0.76 * u, y: o.y + 0.38 * u,
                                               width: 0.10 * u, height: 0.24 * u),
                           cornerRadius: u * 0.03)
                ctx.fill(box, with: line)
                var arrow = Path()
                arrow.move(to: P(0.28, 0.42)); arrow.addLine(to: P(0.62, 0.42))
                arrow.move(to: P(0.52, 0.33)); arrow.addLine(to: P(0.62, 0.42))
                arrow.addLine(to: P(0.52, 0.51))
                arrow.move(to: P(0.62, 0.62)); arrow.addLine(to: P(0.28, 0.62))
                arrow.move(to: P(0.38, 0.53)); arrow.addLine(to: P(0.28, 0.62))
                arrow.addLine(to: P(0.38, 0.71))
                ctx.stroke(arrow, with: line,
                           style: StrokeStyle(lineWidth: u * 0.055, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: size, height: size)
    }

    /// Lingkaran dengan sisi atas dipapas rata — bentuk khas Type 2.
    private func shell(in r: CGRect, flatTop: Bool) -> Path {
        guard flatTop else { return Path(ellipseIn: r) }
        let cut = r.height * 0.17
        var p = Path()
        p.addEllipse(in: r)
        let clipped = p.intersection(Path(CGRect(x: r.minX, y: r.minY + cut,
                                                 width: r.width, height: r.height - cut)))
        var out = clipped
        out.move(to: CGPoint(x: r.minX + r.width * 0.21, y: r.minY + cut))
        out.addLine(to: CGPoint(x: r.maxX - r.width * 0.21, y: r.minY + cut))
        return out
    }
}

// MARK: - Siluet kendaraan

/// Dipakai untuk model yang tidak punya foto berlisensi bebas. Digambar
/// per bentuk bodi, bukan per model — jadi jujur: ini gambar, bukan foto.
struct VehicleArt: View {
    enum Form: String, Codable, Hashable {
        case hatchback, suv, sedan, mpv, van, pickup, scooter, motorcycle

        var label: String {
            switch self {
            case .hatchback:  T("form.hatchback")
            case .suv:        T("form.suv")
            case .sedan:      T("form.sedan")
            case .mpv:        T("form.mpv")
            case .van:        T("form.van")
            case .pickup:     T("form.pickup")
            case .scooter:    T("form.scooter")
            case .motorcycle: T("form.motorcycle")
            }
        }
        var isTwoWheeler: Bool { self == .scooter || self == .motorcycle }
    }

    var style: Form
    var tint: Color = Pal.volt
    var height: CGFloat = 90

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            let shape = Self.path(style, in: CGRect(x: 0, y: 0, width: w, height: h))
            ctx.fill(shape.silhouette, with: .linearGradient(
                Gradient(colors: [tint.opacity(0.55), tint.opacity(0.18)]),
                startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: h)))
            ctx.stroke(shape.silhouette, with: .color(tint.opacity(0.85)),
                       style: StrokeStyle(lineWidth: max(1.2, h * 0.016),
                                          lineJoin: .round))
            ctx.stroke(shape.detail, with: .color(tint.opacity(0.45)),
                       style: StrokeStyle(lineWidth: max(1, h * 0.012), lineCap: .round))
            for wheel in shape.wheels {
                ctx.fill(Path(ellipseIn: wheel), with: .color(Pal.void))
                ctx.stroke(Path(ellipseIn: wheel), with: .color(tint.opacity(0.9)),
                           style: StrokeStyle(lineWidth: max(1.4, h * 0.020)))
                let hub = wheel.insetBy(dx: wheel.width * 0.30, dy: wheel.height * 0.30)
                ctx.fill(Path(ellipseIn: hub), with: .color(tint.opacity(0.5)))
            }
        }
        .frame(height: height)
    }

    private struct Art {
        var silhouette: Path
        var detail: Path
        var wheels: [CGRect]
    }

    /// Semua angka dalam satuan relatif terhadap kotak gambar, jadi bentuknya
    /// sama di kartu kecil maupun di halaman detail.
    private static func path(_ style: Form, in r: CGRect) -> Art {
        let W = r.width, H = r.height
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * W, y: r.minY + y * H) }
        func wheel(_ cx: CGFloat, _ cy: CGFloat, _ d: CGFloat) -> CGRect {
            CGRect(x: r.minX + (cx - d / 2) * W, y: r.minY + cy * H - d * W / 2,
                   width: d * W, height: d * W)
        }
        var s = Path(), d = Path()
        var wheels: [CGRect] = []

        switch style {
        case .scooter, .motorcycle:
            let sporty = style == .motorcycle
            let axle: CGFloat = 0.74
            let dia: CGFloat = sporty ? 0.30 : 0.26
            wheels = [wheel(0.20, axle, dia), wheel(0.80, axle, dia)]
            s.move(to: P(0.12, 0.72))
            s.addCurve(to: P(0.30, 0.50), control1: P(0.14, 0.60), control2: P(0.20, 0.50))
            s.addLine(to: P(sporty ? 0.46 : 0.42, sporty ? 0.40 : 0.52))
            s.addCurve(to: P(0.62, sporty ? 0.34 : 0.40),
                       control1: P(sporty ? 0.54 : 0.50, sporty ? 0.34 : 0.44),
                       control2: P(sporty ? 0.58 : 0.56, sporty ? 0.32 : 0.38))
            s.addLine(to: P(0.74, sporty ? 0.40 : 0.44))
            s.addCurve(to: P(0.88, 0.70), control1: P(0.82, 0.46), control2: P(0.88, 0.58))
            s.addLine(to: P(0.70, 0.76))
            s.addCurve(to: P(0.34, 0.76), control1: P(0.58, 0.82), control2: P(0.46, 0.82))
            s.closeSubpath()
            d.move(to: P(0.26, 0.46))                     // setang
            d.addLine(to: P(0.30, 0.26))
            d.addLine(to: P(0.44, 0.24))
            d.move(to: P(0.30, 0.26))
            d.addLine(to: P(0.18, 0.30))

        case .pickup:
            wheels = [wheel(0.24, 0.76, 0.21), wheel(0.78, 0.76, 0.21)]
            s.move(to: P(0.05, 0.78))
            s.addLine(to: P(0.07, 0.52))
            s.addLine(to: P(0.24, 0.50))
            s.addLine(to: P(0.33, 0.24))
            s.addLine(to: P(0.56, 0.22))
            s.addLine(to: P(0.60, 0.50))
            s.addLine(to: P(0.97, 0.52))
            s.addLine(to: P(0.96, 0.78))
            s.closeSubpath()
            d.move(to: P(0.60, 0.50)); d.addLine(to: P(0.60, 0.78))
            d.move(to: P(0.35, 0.27)); d.addLine(to: P(0.46, 0.26)); d.addLine(to: P(0.46, 0.49))

        default:
            // Mobil: tinggi atap, panjang kap dan kemiringan kaca yang bikin
            // hatchback beda dari SUV dan sedan.
            let roofY: CGFloat
            let noseY: CGFloat
            let tailY: CGFloat
            let roofFront: CGFloat
            let roofBack: CGFloat
            let tailX: CGFloat
            switch style {
            case .suv:  roofY = 0.18; noseY = 0.46; tailY = 0.46; roofFront = 0.33; roofBack = 0.76; tailX = 0.95
            case .sedan:roofY = 0.26; noseY = 0.54; tailY = 0.56; roofFront = 0.36; roofBack = 0.66; tailX = 0.96
            case .mpv:  roofY = 0.16; noseY = 0.48; tailY = 0.44; roofFront = 0.28; roofBack = 0.82; tailX = 0.95
            case .van:  roofY = 0.12; noseY = 0.46; tailY = 0.38; roofFront = 0.22; roofBack = 0.88; tailX = 0.94
            default:    roofY = 0.22; noseY = 0.52; tailY = 0.52; roofFront = 0.34; roofBack = 0.74; tailX = 0.92
            }
            wheels = [wheel(0.26, 0.78, style == .suv ? 0.22 : 0.19),
                      wheel(0.76, 0.78, style == .suv ? 0.22 : 0.19)]
            s.move(to: P(0.04, 0.80))
            s.addCurve(to: P(0.09, noseY), control1: P(0.03, 0.64), control2: P(0.04, noseY + 0.04))
            s.addLine(to: P(roofFront - 0.08, noseY - 0.04))
            s.addCurve(to: P(roofFront, roofY), control1: P(roofFront - 0.04, noseY - 0.10),
                       control2: P(roofFront - 0.02, roofY + 0.04))
            s.addLine(to: P(roofBack - 0.10, roofY - 0.02))
            s.addCurve(to: P(roofBack + 0.06, tailY - 0.06),
                       control1: P(roofBack + 0.02, roofY), control2: P(roofBack + 0.05, tailY - 0.14))
            s.addLine(to: P(tailX, tailY))
            s.addCurve(to: P(tailX - 0.01, 0.80), control1: P(tailX + 0.02, tailY + 0.12),
                       control2: P(tailX + 0.01, 0.72))
            s.closeSubpath()
            // garis pintu dan kaca
            d.move(to: P(roofFront + 0.02, roofY + 0.05))
            d.addLine(to: P(roofBack - 0.06, roofY + 0.04))
            d.move(to: P(0.50, roofY + 0.06)); d.addLine(to: P(0.50, noseY + 0.02))
            d.move(to: P(0.12, noseY + 0.10)); d.addLine(to: P(0.30, noseY + 0.08))
        }
        return Art(silhouette: s, detail: d, wheels: wheels)
    }
}

// MARK: - Gambar kendaraan

/// Pakai fotonya kalau ada; kalau tidak, siluetnya. Dua-duanya duduk di
/// kotak yang sama supaya daftarnya tetap rata.
struct VehicleImage: View {
    var vehicle: Vehicle
    var height: CGFloat = 92
    var tint: Color = Pal.volt
    /// Isi penuh kotaknya dan potong sisanya — dipakai di daftar yang
    /// kotaknya kecil dan rata. Di halaman detail lebih baik muat utuh.
    var fill: Bool = false

    private var photo: String? {
        guard let n = vehicle.photo, UIImage(named: n) != nil else { return nil }
        return n
    }

    var body: some View {
        Group {
            if let photo {
                Image(photo)
                    .resizable()
                    .aspectRatio(contentMode: fill ? .fill : .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .clipped()
                    .overlay {
                        // sapuan gelap tipis supaya fotonya menyatu dengan
                        // kartu, bukan seperti stiker yang ditempel
                        LinearGradient(colors: [.clear, Pal.void.opacity(0.28)],
                                       startPoint: .center, endPoint: .bottom)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: height * 0.12, style: .continuous))
            } else {
                VehicleArt(style: vehicle.style, tint: tint, height: height)
                    .frame(height: height)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// Benar kalau yang tampil foto sungguhan, bukan gambar.
    var isPhoto: Bool { photo != nil }
}
