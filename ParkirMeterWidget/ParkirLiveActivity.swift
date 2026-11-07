import ActivityKit
import SwiftUI
import WidgetKit

struct ParkirLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkirAttributes.self) { context in
            LockScreenCard(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Pal.asphalt.opacity(0.92))
                .activitySystemActionForegroundColor(Pal.sodium)
        } dynamicIsland: { context in
            let s = context.state

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Durasi").stencil(8, tracking: 1.1).foregroundStyle(Pal.inkFaint)
                        Text(timerInterval: s.startedAt...Date.distantFuture,
                             countsDown: false)
                            .font(.meter(21, .semibold))
                            .foregroundStyle(Pal.ink)
                            .frame(width: 78, alignment: .leading)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Biaya").stencil(8, tracking: 1.1).foregroundStyle(Pal.inkFaint)
                        Text(Rupiah.full(s.costNow))
                            .font(.meter(21, .bold))
                            .foregroundStyle(Pal.sodium)
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        TickBar(state: s, compact: true)
                        Text(subtitle(for: context.attributes, state: s))
                            .font(.label(10.5))
                            .foregroundStyle(Pal.inkMuted)
                    }
                    .padding(.top, 2)
                }
            } compactLeading: {
                Image(systemName: "parkingsign")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Pal.sodium)
            } compactTrailing: {
                Text(Rupiah.plain(s.costNow))
                    .font(.meter(13, .bold))
                    .foregroundStyle(Pal.sodium)
            } minimal: {
                Image(systemName: "parkingsign")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(Pal.sodium)
            }
            .keylineTint(Pal.sodium)
        }
    }

    private func subtitle(for a: ParkirAttributes, state s: ParkirAttributes.ContentState) -> String {
        var bits = [a.location]
        if !a.plate.isEmpty { bits.append(a.plate) }
        bits.append(Rupiah.full(s.ratePerHour) + "/jam")
        return bits.filter { !$0.isEmpty }.joined(separator: "  ·  ")
    }
}

// MARK: - Layar kunci

private struct LockScreenCard: View {
    let attributes: ParkirAttributes
    let state: ParkirAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: "parkingsign")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Pal.sodium)
                Text(attributes.location.isEmpty ? "Parkir" : attributes.location)
                    .stencil(10, tracking: 1.5)
                    .foregroundStyle(Pal.sodium)
                Spacer()
                if !attributes.plate.isEmpty {
                    Text(attributes.plate)
                        .font(.meter(10.5, .bold))
                        .foregroundStyle(Pal.inkMuted)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Capsule().stroke(Pal.line, lineWidth: 1))
                }
            }
            .padding(.bottom, 14)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(timerInterval: state.startedAt...Date.distantFuture, countsDown: false)
                        .font(.meter(32, .semibold))
                        .foregroundStyle(Pal.ink)
                        .frame(width: 128, alignment: .leading)
                    Text("durasi").stencil(8, tracking: 1.2).foregroundStyle(Pal.inkFaint)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 3) {
                    PriceTag(value: state.costNow, size: 30, color: Pal.sodium)
                    Text("sejauh ini").stencil(8, tracking: 1.2).foregroundStyle(Pal.inkFaint)
                }
            }

            TickBar(state: state, compact: false)
                .padding(.top, 15)
        }
        .padding(17)
    }
}

// MARK: - Bar menuju lompatan harga

private struct TickBar: View {
    let state: ParkirAttributes.ContentState
    var compact: Bool

    var body: some View {
        if let at = state.nextTickAt, let cost = state.nextTickCost {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8, weight: .black))
                    Text("naik ke \(Rupiah.full(cost)) dalam")
                        .font(.label(compact ? 10 : 11))
                    Text(timerInterval: Date()...at, countsDown: true)
                        .font(.meter(compact ? 10 : 11, .bold))
                        .frame(width: 44, alignment: .leading)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(Pal.inkMuted)

                ProgressView(timerInterval: at.addingTimeInterval(-3600)...at, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .progressViewStyle(.linear)
                .tint(Pal.sodium)
                .frame(height: 3)
            }
        } else {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 8, weight: .bold))
                Text("dihitung per menit · \(Rupiah.full(state.ratePerHour))/jam")
                    .font(.label(compact ? 10 : 11))
                Spacer(minLength: 0)
            }
            .foregroundStyle(Pal.inkMuted)
        }
    }
}
