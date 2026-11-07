import AVFoundation
import SwiftUI

/// Pemicu pengisian. Di SPKLU asli kode QR-nya tertempel di badan charger;
/// di sini kameranya betulan dibuka kalau ada. Memindai TIDAK langsung
/// mengisi — hasilnya cuma membuka lembar persetujuan.
struct ScanScreen: View {
    @EnvironmentObject private var store: ChargeStore
    @Environment(\.dismiss) private var dismiss
    @State private var typed = ""
    @State private var manual = false
    @State private var error: String?
    @State private var sweep = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CameraLayer { code in handle(code) }
                .ignoresSafeArea()

            LinearGradient(colors: [.black.opacity(0.75), .black.opacity(0.25), .black.opacity(0.85)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                bar
                Spacer()
                viewfinder
                Spacer()
                bottom
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $manual) { manualSheet }
    }

    // MARK: Bagian atas

    private var bar: some View {
        HStack {
            BackButton { dismiss() }
            Spacer()
            Text(T("scan.title")).stencil(12, tracking: 2).foregroundStyle(Pal.ink)
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: Bingkai pindai

    private var viewfinder: some View {
        VStack(spacing: 22) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Pal.ink.opacity(0.12), lineWidth: 1)
                Corners().stroke(Pal.volt, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, Pal.volt.opacity(0.75), .clear],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(height: 2)
                    .offset(y: sweep ? 110 : -110)
                    .shadow(color: Pal.volt.opacity(0.6), radius: 7)
            }
            .frame(width: 248, height: 248)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) {
                    sweep = true
                }
            }

            VStack(spacing: 7) {
                Text(T("scan.aim"))
                    .font(.label(14, .semibold)).foregroundStyle(Pal.ink)
                Text(T("scan.stillApprove"))
                    .font(.label(11.5))
                    .foregroundStyle(Pal.inkMuted)
                    .multilineTextAlignment(.center)
            }

            if let error {
                Text(error)
                    .font(.label(12, .semibold))
                    .foregroundStyle(Pal.alarm)
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(Capsule().fill(Pal.alarm.opacity(0.14)))
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: Bagian bawah

    private var bottom: some View {
        VStack(spacing: 12) {
            Button { manual = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "keyboard").font(.system(size: 13, weight: .bold))
                    Text(T("scan.manualButton")).font(.label(13.5, .semibold))
                }
                .foregroundStyle(Pal.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Pal.surface.opacity(0.9)))
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(Pal.line, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Text(CameraLayer.available
                 ? T("scan.hintCamera")
                 : T("scan.hintNoCamera"))
                .font(.label(10.5)).foregroundStyle(Pal.inkFaint)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 26)
    }

    // MARK: Kode manual

    private var manualSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text(T("scan.codeTitle")).stencil(12, tracking: 2).foregroundStyle(Pal.ink)
                Text(T("scan.codeHelp"))
                    .font(.label(12)).foregroundStyle(Pal.inkMuted)

                HStack(spacing: 9) {
                    TextField("", text: $typed,
                              prompt: Text("ZTR-GBK1").foregroundStyle(Pal.inkFaint))
                        .font(.meter(18, .bold))
                        .foregroundStyle(Pal.ink)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .tint(Pal.volt)
                        .padding(.horizontal, 14)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Pal.slab))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Pal.line, lineWidth: 1))
                    Button {
                        manual = false
                        handle(typed)
                    } label: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Pal.void)
                            .frame(width: 52, height: 52)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Pal.volt))
                    }
                    .buttonStyle(.plain)
                }

                SectionHead(title: T("scan.nearbyCodes"))
                ForEach(Array(store.nearby().prefix(6))) { p in
                    VStack(alignment: .leading, spacing: 7) {
                        Text(p.name).font(.label(12.5, .bold)).foregroundStyle(Pal.ink)
                        ForEach(p.units) { u in
                            Button {
                                manual = false
                                handle(u.code)
                            } label: {
                                HStack(spacing: 10) {
                                    Text(u.code).font(.meter(12.5, .bold)).foregroundStyle(Pal.volt)
                                    Text(u.headline).font(.label(10.5)).foregroundStyle(Pal.inkMuted)
                                    Spacer()
                                    StatusTag(status: u.status, compact: true)
                                }
                                .padding(.horizontal, 11).padding(.vertical, 9)
                                .background(RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Pal.slab))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Pal.surface))
                    .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Pal.line, lineWidth: 1))
                }
            }
            .padding(18)
        }
        .scrollIndicators(.hidden)
        .background(Pal.void)
        .presentationBackground(Pal.void)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: Hasil pindaian

    private func handle(_ raw: String) {
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        if store.scanned(code: code) {
            dismiss()
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                error = T("scan.unknown", code.uppercased())
            }
            Haptic.thud()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                withAnimation { error = nil }
            }
        }
    }
}

// MARK: - Sudut bingkai

private struct Corners: Shape {
    var arm: CGFloat = 34
    var radius: CGFloat = 28

    func path(in r: CGRect) -> Path {
        var p = Path()
        // kiri atas
        p.move(to: CGPoint(x: r.minX, y: r.minY + radius + arm))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + radius))
        p.addQuadCurve(to: CGPoint(x: r.minX + radius, y: r.minY),
                       control: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX + radius + arm, y: r.minY))
        // kanan atas
        p.move(to: CGPoint(x: r.maxX - radius - arm, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - radius, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + radius),
                       control: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + radius + arm))
        // kanan bawah
        p.move(to: CGPoint(x: r.maxX, y: r.maxY - radius - arm))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - radius))
        p.addQuadCurve(to: CGPoint(x: r.maxX - radius, y: r.maxY),
                       control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX - radius - arm, y: r.maxY))
        // kiri bawah
        p.move(to: CGPoint(x: r.minX + radius + arm, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + radius, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - radius),
                       control: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - radius - arm))
        return p
    }
}

// MARK: - Kamera

/// Kalau tidak ada kamera (misalnya di simulator), yang tampil cuma layar
/// hitam dan jalur kode manual tetap bisa dipakai.
struct CameraLayer: UIViewRepresentable {
    var onCode: (String) -> Void

    static var available: Bool {
        AVCaptureDevice.default(for: .video) != nil
    }

    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode) }

    func makeUIView(context: Context) -> PreviewView {
        let v = PreviewView()
        guard Self.available else { return v }
        context.coordinator.start(on: v)
        return v
    }

    func updateUIView(_ v: PreviewView, context: Context) {}

    static func dismantleUIView(_ v: PreviewView, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var preview: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        private let session = AVCaptureSession()
        private let onCode: (String) -> Void
        private var done = false

        init(onCode: @escaping (String) -> Void) { self.onCode = onCode }

        func start(on view: PreviewView) {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] ok in
                guard ok, let self else { return }
                DispatchQueue.global(qos: .userInitiated).async {
                    guard let device = AVCaptureDevice.default(for: .video),
                          let input = try? AVCaptureDeviceInput(device: device),
                          self.session.canAddInput(input) else { return }
                    self.session.beginConfiguration()
                    self.session.addInput(input)
                    let out = AVCaptureMetadataOutput()
                    if self.session.canAddOutput(out) {
                        self.session.addOutput(out)
                        out.setMetadataObjectsDelegate(self, queue: .main)
                        out.metadataObjectTypes = [.qr]
                    }
                    self.session.commitConfiguration()
                    DispatchQueue.main.async {
                        view.preview.session = self.session
                        view.preview.videoGravity = .resizeAspectFill
                    }
                    self.session.startRunning()
                }
            }
        }

        func stop() {
            if session.isRunning { session.stopRunning() }
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput objects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            guard !done,
                  let o = objects.first as? AVMetadataMachineReadableCodeObject,
                  let s = o.stringValue else { return }
            done = true
            stop()
            onCode(s)
        }
    }
}
