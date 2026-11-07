import ActivityKit
import SwiftUI
import WidgetKit

struct ZetrumLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ZetrumAttributes.self) { context in
            LockScreenCard(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Pal.void.opacity(0.94))
                .activitySystemActionForegroundColor(Pal.volt)
        } dynamicIsland: { context in
            let s = context.state
            let tint = s.isDone ? Pal.ion : Pal.volt

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Baterai").stencil(8, tracking: 1.1).foregroundStyle(Pal.inkFaint)
                        UnitTag(text: Energi.persen(s.soc), unit: "%", size: 22, color: Pal.ink)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Biaya").stencil(8, tracking: 1.1).foregroundStyle(Pal.inkFaint)
                        Text(Rupiah.full(s.cost))
                            .font(.meter(21, .bold))
                            .foregroundStyle(tint)
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 9) {
                        BatteryPack(soc: s.soc, target: s.plan.targetSoC,
                                    tint: tint, charging: !s.isDone, cells: 20, height: 16)
                        HStack(spacing: 0) {
                            Text("\(Energi.kwh(s.energy)) kWh masuk")
                                .font(.label(10.5))
                                .foregroundStyle(Pal.inkMuted)
                            Spacer(minLength: 8)
                            Countdown(state: s, size: 10.5)
                        }
                    }
                    .padding(.top, 2)
                }
            } compactLeading: {
                Bolt()
                    .fill(tint)
                    .frame(width: 9, height: 13)
            } compactTrailing: {
                Text("\(Energi.persen(s.soc))%")
                    .font(.meter(13, .bold))
                    .foregroundStyle(tint)
            } minimal: {
                Bolt()
                    .fill(tint)
                    .frame(width: 9, height: 13)
            }
            .keylineTint(tint)
        }
    }
}

// MARK: - Layar kunci

private struct LockScreenCard: View {
    let attributes: ZetrumAttributes
    let state: ZetrumAttributes.ContentState

    private var tint: Color { state.isDone ? Pal.ion : Pal.volt }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                BoltMark(size: 24, tint: tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text(attributes.stationName)
                        .font(.label(12.5, .bold))
                        .foregroundStyle(Pal.ink)
                    Text(attributes.carName)
                        .font(.label(10))
                        .foregroundStyle(Pal.inkMuted)
                }
                Spacer()
                Text(attributes.powerLabel)
                    .font(.meter(10.5, .bold))
                    .foregroundStyle(Pal.inkMuted)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Capsule().stroke(Pal.line, lineWidth: 1))
            }
            .padding(.bottom, 13)

            HStack(alignment: .firstTextBaseline) {
                UnitTag(text: Energi.persen(state.soc), unit: "%", size: 34, color: Pal.ink)
                Spacer(minLength: 8)
                PriceTag(value: state.cost, size: 28, color: tint)
            }
            .padding(.bottom, 11)

            BatteryPack(soc: state.soc, target: state.plan.targetSoC,
                        tint: tint, charging: !state.isDone, cells: 22, height: 15)

            HStack(spacing: 0) {
                Text("\(Energi.kwh(state.energy)) kWh")
                    .font(.meter(11, .bold))
                    .foregroundStyle(Pal.inkMuted)
                Text("  masuk")
                    .font(.label(11))
                    .foregroundStyle(Pal.inkFaint)
                Spacer(minLength: 8)
                Countdown(state: state, size: 11)
            }
            .padding(.top, 11)
        }
        .padding(16)
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
                Text("sudah penuh").font(.label(size, .semibold))
            }
            .foregroundStyle(Pal.ion)
        } else if let finish = state.finishAt, finish > Date() {
            HStack(spacing: 4) {
                Image(systemName: "hourglass")
                    .font(.system(size: size * 0.85, weight: .bold))
                Text("penuh dalam").font(.label(size))
                Text(timerInterval: Date()...finish, countsDown: true)
                    .font(.meter(size, .bold))
                    .frame(width: size * 4.2, alignment: .leading)
            }
            .foregroundStyle(Pal.ion)
        } else {
            Text("mengisi…")
                .font(.label(size))
                .foregroundStyle(Pal.inkMuted)
        }
    }
}
