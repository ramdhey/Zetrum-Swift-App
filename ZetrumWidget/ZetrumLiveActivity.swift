import ActivityKit
import SwiftUI
import WidgetKit

/// Live Activity Zetrum.
///
/// Soal gerak: sistem menggambar Live Activity dari potret yang sudah
/// dibekukan, jadi animasi berulang tidak pernah dijalankan. Yang betul-betul
/// bisa bergerak sendiri cuma dua: `Text(timerInterval:)` dan
/// `ProgressView(timerInterval:)`. Keduanya dipakai di sini sebagai "rel
/// waktu" — garis biru es yang terus merayap ke kanan walaupun aplikasinya
/// sedang tidur.
///
/// Sisanya bergerak tiap kabar baru datang: sel baterai menyala berangsur,
/// angka berguling, dan warnanya memudar dari hijau setrum ke biru es begitu
/// target tercapai.
///
/// Dua gerak itu sengaja dibedakan warnanya — hijau untuk baterai, biru es
/// untuk waktu — supaya rel waktu tidak terbaca sebagai permukaan baterai.
struct ZetrumLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ZetrumAttributes.self) { context in
            LockScreenCard(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Pal.void.opacity(0.94))
                .activitySystemActionForegroundColor(Pal.volt)
        } dynamicIsland: { context in
            let s = context.state
            adoptLanguage(s.lang)
            let tint = s.isDone ? Pal.ion : Pal.volt

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(T("la.battery")).stencil(8, tracking: 1.1).foregroundStyle(Pal.inkFaint)
                        UnitTag(text: Energi.persen(s.soc), unit: "%", size: 22, color: Pal.ink)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(T("la.cost")).stencil(8, tracking: 1.1).foregroundStyle(Pal.inkFaint)
                        Text(Rupiah.full(s.cost))
                            .font(.meter(21, .bold))
                            .foregroundStyle(tint)
                            .contentTransition(.numericText())
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        BatteryPack(soc: s.soc, target: s.plan.targetSoC,
                                    tint: tint, charging: !s.isDone, pulse: false,
                                    cells: 20, height: 16)
                        TimeRail(state: s)
                        HStack(spacing: 0) {
                            Text(T("la.kwhIn", Energi.kwh(s.energy)))
                                .font(.label(10.5))
                                .foregroundStyle(Pal.inkMuted)
                                .contentTransition(.numericText())
                            Spacer(minLength: 8)
                            Countdown(state: s, size: 10.5)
                        }
                    }
                    .padding(.top, 2)
                    .animation(.default, value: s.soc)
                    .animation(.default, value: s.isDone)
                }
            } compactLeading: {
                CompactRing(state: s, tint: tint)
            } compactTrailing: {
                Text("\(Energi.persen(s.soc))%")
                    .font(.meter(13, .bold))
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
            } minimal: {
                CompactRing(state: s, tint: tint)
            }
            .keylineTint(tint)
        }
    }
}

// MARK: - Bahasa

/// Widget jalan di proses sendiri dan tidak bisa membaca pengaturan
/// aplikasi, jadi bahasanya dibaca dari kabar yang baru masuk — dipasang
/// sebelum apa pun digambar.
@discardableResult
private func adoptLanguage(_ raw: String) -> Bool {
    Loc.lang = Lang(rawValue: raw) ?? .indonesian
    return true
}

// MARK: - Rel waktu

/// Garis yang mengisi dirinya sendiri dari jam mulai sampai jam selesai.
/// Tidak butuh kabar dari aplikasi sama sekali — jadi tetap merayap walau
/// prosesnya sudah dimatikan iOS. Warnanya biru es, beda dari sel baterai,
/// supaya jelas ini kemajuan waktu, bukan permukaan baterai.
private struct TimeRail: View {
    let state: ZetrumAttributes.ContentState

    private var span: ClosedRange<Date>? {
        guard let finish = state.finishAt, finish > state.startedAt else { return nil }
        return state.startedAt...finish
    }

    var body: some View {
        if let span, !state.isDone {
            ProgressView(timerInterval: span, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.linear)
            .tint(Pal.ion)
        }
    }
}

/// Cincin di Dynamic Island yang juga mengisi dirinya sendiri. Ini satu-satunya
/// gerak yang kelihatan waktu HP cuma diintip sekilas.
private struct CompactRing: View {
    let state: ZetrumAttributes.ContentState
    let tint: Color

    var body: some View {
        if let finish = state.finishAt, !state.isDone, finish > state.startedAt {
            ProgressView(timerInterval: state.startedAt...finish, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.circular)
            .tint(tint)
        } else if state.isDone {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
        } else {
            Bolt().fill(tint).frame(width: 9, height: 13)
        }
    }
}

// MARK: - Layar kunci

private struct LockScreenCard: View {
    let attributes: ZetrumAttributes
    let state: ZetrumAttributes.ContentState

    private var tint: Color { state.isDone ? Pal.ion : Pal.volt }

    var body: some View {
        let _ = adoptLanguage(state.lang)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                BoltMark(size: 24, tint: tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text(attributes.stationName)
                        .font(.label(12.5, .bold))
                        .foregroundStyle(Pal.ink)
                    HStack(spacing: 4) {
                        Image(systemName: attributes.isBike ? "scooter" : "car.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text(attributes.carName).font(.label(10))
                    }
                    .foregroundStyle(Pal.inkMuted)
                }
                Spacer()
                Text(attributes.powerLabel)
                    .font(.meter(10.5, .bold))
                    .foregroundStyle(Pal.inkMuted)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Capsule().stroke(Pal.line, lineWidth: 1))
            }
            .padding(.bottom, 11)

            HStack(alignment: .firstTextBaseline) {
                UnitTag(text: Energi.persen(state.soc), unit: "%", size: 34, color: Pal.ink)
                Spacer(minLength: 8)
                PriceTag(value: state.cost, size: 28, color: tint)
            }
            .padding(.bottom, 10)

            BatteryPack(soc: state.soc, target: state.plan.targetSoC,
                        tint: tint, charging: !state.isDone, pulse: false,
                        cells: 22, height: 15)

            // Di layar kunci tingginya dijatah ketat (batas sistem sekitar
            // 160 poin), jadi relnya garis rambut saja tanpa label jam —
            // jam selesainya sudah disebut hitung mundur di bawah.
            TimeRail(state: state)
                .padding(.top, 7)

            HStack(spacing: 0) {
                Text("\(Energi.kwh(state.energy)) kWh")
                    .font(.meter(11, .bold))
                    .foregroundStyle(Pal.inkMuted)
                    .contentTransition(.numericText())
                Text(T("la.in"))
                    .font(.label(11))
                    .foregroundStyle(Pal.inkFaint)
                Spacer(minLength: 8)
                Countdown(state: state, size: 11)
            }
            .padding(.top, 8)
        }
        .padding(14)
        // yang ini jalan tiap kabar baru datang: angka berguling, sel
        // menyala berangsur, dan warnanya memudar waktu sudah penuh
        .animation(.default, value: state.soc)
        .animation(.easeInOut(duration: 0.7), value: state.isDone)
    }
}

// MARK: - Hitung mundur

/// Waktu selesai sudah dihitung di depan, jadi hitung mundurnya berjalan
/// sendiri di layar kunci tanpa aplikasi perlu dibangunkan.
private struct Countdown: View {
    let state: ZetrumAttributes.ContentState
    var size: CGFloat

    var body: some View {
        if state.isDone {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: size * 0.9, weight: .bold))
                Text(T("la.done")).font(.label(size, .semibold))
            }
            .foregroundStyle(Pal.ion)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        } else if let finish = state.finishAt, finish > Date() {
            HStack(spacing: 4) {
                Image(systemName: "hourglass")
                    .font(.system(size: size * 0.85, weight: .bold))
                Text(T("la.fullIn")).font(.label(size))
                Text(timerInterval: Date()...finish, countsDown: true)
                    .font(.meter(size, .bold))
                    .frame(width: size * 4.2, alignment: .leading)
            }
            .foregroundStyle(Pal.ion)
            .transition(.opacity)
        } else {
            Text(T("la.charging"))
                .font(.label(size))
                .foregroundStyle(Pal.inkMuted)
        }
    }
}
