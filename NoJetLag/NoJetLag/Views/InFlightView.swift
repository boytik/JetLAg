import SwiftUI
import Combine

/// In-flight surface: shown on the Now tab while `Trip.isCurrentlyInFlight`.
/// Big countdown to landing, dual origin/destination time, an instant
/// sleep-or-wake recommendation based on destination time, in-flight checklist,
/// and an OFFLINE-OK indicator.
///
/// Everything on this view is computed locally — nothing here makes network
/// calls. That is the point: the screen the user opens at 35,000ft has to work.
struct InFlightView: View {
    let trip: Trip
    let now: Date

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                offlineHeader
                countdownCard
                dualTime
                advice
                checklist
                hydrationFootnote
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - Pieces

    private var offlineHeader: some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: 6) {
                Circle().fill(Color.caffeineGreen).frame(width: 5, height: 5)
                Text("OFFLINE-OK")
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.4)
                    .foregroundStyle(Color.caffeineGreen)
            }
            Spacer()
            Text("IN FLIGHT · \(routeText)")
                .font(Typography.mono(10, weight: .semibold))
                .trackedUppercase(1.4)
                .foregroundStyle(Color.textLo)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.bottom, Spacing.xs)
        .overlay(alignment: .bottom) { Hairline() }
    }

    private var countdownCard: some View {
        ActiveCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    HStack(spacing: Spacing.sm) {
                        PulsingDot(size: 6)
                        Text("TO LANDING")
                            .font(Typography.mono(10, weight: .semibold))
                            .trackedUppercase(1.6)
                            .foregroundStyle(Color.amber)
                    }
                    Spacer()
                    if let progress = trip.flightProgress(at: now) {
                        Text(String(format: "%02d%%", Int(progress * 100)))
                            .font(Typography.mono(10, weight: .semibold))
                            .trackedUppercase(1.4)
                            .foregroundStyle(Color.textLo)
                    }
                }

                Text(landingCountdownText)
                    .font(Typography.mono(48, weight: .medium))
                    .foregroundStyle(Color.amber)
                    .tracking(-1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if let progress = trip.flightProgress(at: now) {
                    progressBar(progress)
                }

                HStack {
                    Text("DEP \(timeText(trip.departure, tz: trip.originTimeZone)) \(tzAbbr(trip.originTimeZone))")
                        .font(Typography.mono(11, weight: .medium))
                        .foregroundStyle(Color.textMid)
                    Spacer()
                    Text("ARR \(timeText(trip.arrival, tz: trip.destinationTimeZone)) \(tzAbbr(trip.destinationTimeZone))")
                        .font(Typography.mono(11, weight: .medium))
                        .foregroundStyle(Color.textMid)
                }
            }
        }
    }

    private func progressBar(_ progress: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.bg2)
                    .frame(height: 2)
                Rectangle()
                    .fill(Color.amber)
                    .frame(width: geo.size.width * CGFloat(progress), height: 2)
            }
        }
        .frame(height: 2)
    }

    private var dualTime: some View {
        HStack(spacing: Spacing.md) {
            timeColumn(
                label: "ORIGIN",
                code: trip.originTimeZoneId,
                tz: trip.originTimeZone
            )
            Rectangle()
                .fill(Color.stroke)
                .frame(width: 1, height: 56)
            timeColumn(
                label: "DESTINATION",
                code: trip.destinationTimeZoneId,
                tz: trip.destinationTimeZone,
                accent: true
            )
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.bg1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.stroke, lineWidth: 1)
        )
    }

    private func timeColumn(label: String, code: String, tz: TimeZone, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Typography.mono(9, weight: .semibold))
                .trackedUppercase(1.6)
                .foregroundStyle(Color.textLo)
            Text(timeText(now, tz: tz))
                .font(Typography.mono(32, weight: .medium))
                .foregroundStyle(accent ? Color.amber : Color.textHi)
                .tracking(-0.5)
            Text("\(tzAbbr(tz)) · \(cityName(code))")
                .font(Typography.mono(10, weight: .medium))
                .foregroundStyle(Color.textLo)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var advice: some View {
        let rec = recommendation
        return InstrumentCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("RIGHT NOW")
                        .font(Typography.mono(10, weight: .semibold))
                        .trackedUppercase(1.6)
                        .foregroundStyle(rec.color)
                    Spacer()
                    Text(rec.badge)
                        .font(Typography.mono(9, weight: .semibold))
                        .trackedUppercase(1.4)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .foregroundStyle(rec.color)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.sm)
                                .stroke(rec.color, lineWidth: 1)
                        )
                }
                Text(rec.title)
                    .font(Typography.display(22, weight: .semibold))
                    .foregroundStyle(rec.color)
                Text(rec.detail)
                    .font(Typography.body(13))
                    .foregroundStyle(Color.textMid)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var checklist: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionTag(text: "WHILE YOU'RE UP THERE")
                .padding(.horizontal, Spacing.xs)
            InstrumentCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Self.flightTips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: Spacing.md) {
                            Text("·")
                                .font(Typography.mono(13, weight: .semibold))
                                .foregroundStyle(Color.amber)
                                .frame(width: 8)
                            Text(tip)
                                .font(Typography.body(13))
                                .foregroundStyle(Color.textMid)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        if tip != Self.flightTips.last {
                            Hairline()
                        }
                    }
                }
            }
        }
    }

    private var hydrationFootnote: some View {
        Text("All advice is pre-computed. No internet required for the rest of the flight.")
            .font(Typography.body(11))
            .foregroundStyle(Color.textLo)
            .padding(.horizontal, Spacing.xs)
    }

    // MARK: - Recommendation logic

    private struct Recommendation {
        let title: String
        let detail: String
        let badge: String
        let color: Color
    }

    /// Decide what the user should be doing right now based on **destination
    /// local time**. The protocol is to align with destination night/day so
    /// the user lands closer to in-phase.
    private var recommendation: Recommendation {
        let cal = Calendar(identifier: .gregorian)
        var c = cal
        c.timeZone = trip.destinationTimeZone
        let hour = c.component(.hour, from: now)

        // Treat 22:00 — 06:00 destination time as nighttime → sleep window.
        let isNight = (hour >= 22 || hour < 6)
        // Treat 06:00 — 09:00 as wake/morning → strong stay-awake + light.
        let isMorning = (hour >= 6 && hour < 9)

        if isNight {
            return Recommendation(
                title: "TRY TO SLEEP",
                detail: "It's nighttime at your destination. Eye mask, earplugs, recline. Skip the meal service if it interrupts the sleep window — you can eat after landing.",
                badge: "SLEEP",
                color: Color.sleepIndigo
            )
        } else if isMorning {
            return Recommendation(
                title: "STAY AWAKE · SEEK LIGHT",
                detail: "It's morning at your destination. Keep the window shade open if you can. Bright cabin light helps. No napping — push through to local night.",
                badge: "LIGHT",
                color: Color.amber
            )
        } else {
            return Recommendation(
                title: "STAY AWAKE",
                detail: "It's daytime at your destination. Stay upright, hydrate, move. Save sleep for the destination's nighttime.",
                badge: "AWAKE",
                color: Color.amber
            )
        }
    }

    // MARK: - Static content

    private static let flightTips: [String] = [
        "Drink water every hour — cabin air is dry and dehydration worsens jet lag.",
        "Stretch every 90 minutes. Calf raises in your seat help with circulation.",
        "Skip alcohol and minimize caffeine. Both fragment sleep and dehydrate.",
        "If sleeping: eye mask, earplugs or noise-cancelling, recline as far as the seat allows.",
        "Reset your watch to destination time only if it doesn't make you anxious."
    ]

    // MARK: - Formatting

    private func timeText(_ date: Date, tz: TimeZone) -> String {
        let f = DateFormatter()
        f.timeZone = tz
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    private func tzAbbr(_ tz: TimeZone) -> String {
        tz.abbreviation() ?? ""
    }

    private func cityName(_ id: String) -> String {
        id.split(separator: "/").last.map { String($0).replacingOccurrences(of: "_", with: " ") } ?? id
    }

    private var routeText: String {
        let o = airportCode(trip.originTimeZoneId)
        let d = airportCode(trip.destinationTimeZoneId)
        return "\(o) → \(d)"
    }

    private func airportCode(_ tzId: String) -> String {
        let last = tzId.split(separator: "/").last.map(String.init) ?? tzId
        let cleaned = last.replacingOccurrences(of: "_", with: "")
        return String(cleaned.prefix(3)).uppercased()
    }

    private var landingCountdownText: String {
        guard let secs = trip.timeToLanding(at: now), secs > 0 else { return "00:00" }
        let total = Int(secs)
        let h = total / 3600
        let m = (total % 3600) / 60
        return String(format: "T-%02d:%02d", h, m)
    }
}
