import SwiftUI
import Combine

/// Current/next-action card. The first thing the user opens during a trip.
struct NowView: View {
    @EnvironmentObject private var state: AppState
    @State private var now = Date()
    @State private var showingNewTrip = false

    private let ticker = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg0.ignoresSafeArea()
                Group {
                    if state.trip == nil {
                        emptyState
                    } else {
                        content
                    }
                }
            }
            .navigationTitle("NOW")
            .toolbar {
                if let trip = state.trip {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        navStatus(for: trip)
                    }
                }
            }
            .sheet(isPresented: $showingNewTrip) {
                NewTripView()
            }
            .onReceive(ticker) { now = $0 }
        }
    }

    // MARK: - Subviews

    private var content: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                if let current = state.currentEvent(at: now) {
                    activeCard(event: current)
                } else if let next = state.nextEvent(after: now) {
                    nextCard(event: next)
                } else {
                    completionCard
                }

                if let trip = state.trip {
                    tripSummary(trip)
                }

                upcomingList
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: Cards

    private func activeCard(event: PlanEvent) -> some View {
        ActiveCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    HStack(spacing: Spacing.sm) {
                        PulsingDot(size: 6)
                        Text("RIGHT NOW")
                            .font(Typography.mono(10, weight: .semibold))
                            .trackedUppercase(1.6)
                            .foregroundStyle(Color.amber)
                    }
                    Spacer()
                    if let end = event.endsAt {
                        Text("UNTIL \(timeString(end, tz: event.displayTimeZone))")
                            .font(Typography.mono(10, weight: .semibold))
                            .trackedUppercase(1.4)
                            .foregroundStyle(Color.textLo)
                    }
                }

                Text(event.kind.title.uppercased())
                    .font(Typography.display(26, weight: .semibold))
                    .foregroundStyle(Color.amber)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let end = event.endsAt {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                        Text(remainingString(until: end))
                            .font(Typography.mono(28, weight: .medium))
                            .foregroundStyle(Color.textHi)
                            .tracking(-0.5)
                        Text("REMAINING")
                            .font(Typography.mono(10, weight: .semibold))
                            .trackedUppercase(1.6)
                            .foregroundStyle(Color.textLo)
                    }
                }

                Text(timeRange(event))
                    .font(Typography.mono(12, weight: .medium))
                    .foregroundStyle(Color.textMid)
                    .tracking(0.5)

                if let note = event.note {
                    Text(note)
                        .font(Typography.body(13))
                        .foregroundStyle(Color.textMid)
                        .padding(.top, Spacing.xs)
                }
            }
        }
    }

    private func nextCard(event: PlanEvent) -> some View {
        InstrumentCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionTag(
                    text: "NEXT UP",
                    color: .textLo,
                    trailing: timeString(event.startsAt, tz: event.displayTimeZone)
                )
                Text(event.kind.title)
                    .font(Typography.display(22, weight: .semibold))
                    .foregroundStyle(Color.textHi)
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    Text(countdown(to: event.startsAt))
                        .font(Typography.mono(20, weight: .medium))
                        .foregroundStyle(Color.amber)
                    Spacer()
                    EventBadge(kind: event.kind)
                }
                if let note = event.note {
                    Text(note)
                        .font(Typography.body(13))
                        .foregroundStyle(Color.textMid)
                        .padding(.top, Spacing.xs)
                }
            }
        }
    }

    private var completionCard: some View {
        InstrumentCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionTag(text: "ALL DONE")
                Text("Protocol complete")
                    .font(Typography.display(22, weight: .semibold))
                    .foregroundStyle(Color.textHi)
                Text("Your circadian system should now be aligned with the destination timezone.")
                    .font(Typography.body(13))
                    .foregroundStyle(Color.textMid)
            }
        }
    }

    // MARK: Trip summary

    private func tripSummary(_ trip: Trip) -> some View {
        InstrumentCard(padding: Spacing.md) {
            HStack {
                Text(routeText(trip))
                    .font(Typography.mono(16, weight: .medium))
                    .foregroundStyle(Color.textHi)
                    .tracking(0.5)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(shiftText(trip))
                        .font(Typography.mono(10, weight: .semibold))
                        .trackedUppercase(1.4)
                        .foregroundStyle(Color.amber)
                    Text(trip.name)
                        .font(Typography.body(11))
                        .foregroundStyle(Color.textLo)
                        .lineLimit(1)
                }
            }
        }
    }

    // MARK: Upcoming list

    private var upcomingList: some View {
        let upcoming = Array(state.plan.filter { $0.startsAt > now }.prefix(4))
        return Group {
            if !upcoming.isEmpty {
                InstrumentCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        SectionTag(
                            text: "UPCOMING",
                            color: .textLo,
                            trailing: upcoming.first?.displayTimeZone.abbreviation()
                        )
                        .padding(.bottom, Spacing.xs)

                        HStack(alignment: .top, spacing: Spacing.md) {
                            AltitudeRule()
                                .frame(maxHeight: .infinity)
                            VStack(spacing: 0) {
                                ForEach(Array(upcoming.enumerated()), id: \.element.id) { idx, ev in
                                    EventRow(event: ev)
                                    if idx < upcoming.count - 1 {
                                        Hairline()
                                    }
                                }
                            }
                        }
                        .frame(minHeight: 40)
                    }
                }
            }
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            VStack(spacing: Spacing.sm) {
                Text("NO ACTIVE TRIP")
                    .font(Typography.mono(11, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.textLo)
                Text("Add your flight to begin the protocol.")
                    .font(Typography.body(15))
                    .foregroundStyle(Color.textMid)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingNewTrip = true
            } label: {
                Text("PLAN A TRIP")
                    .trackedUppercase(1.4)
            }
            .buttonStyle(.instrument)
            .padding(.horizontal, Spacing.xxl)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.lg)
    }

    // MARK: Nav-status accessory

    private func navStatus(for trip: Trip) -> some View {
        let totalDays = max(1, dayCount(for: trip))
        let day = max(1, currentDayIndex(for: trip))
        return VStack(alignment: .trailing, spacing: 1) {
            Text("DAY \(String(format: "%02d", day)) / \(String(format: "%02d", totalDays))")
                .font(Typography.mono(9, weight: .semibold))
                .trackedUppercase(1.4)
                .foregroundStyle(Color.textLo)
            HStack(spacing: 4) {
                Circle().fill(Color.amber).frame(width: 5, height: 5)
                Text("ON TRACK")
                    .font(Typography.mono(9, weight: .semibold))
                    .trackedUppercase(1.4)
                    .foregroundStyle(Color.amber)
            }
        }
    }

    private func dayCount(for trip: Trip) -> Int {
        guard let first = state.plan.first?.startsAt,
              let last = state.plan.last?.startsAt else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: first, to: last).day ?? 0
        return max(1, days + 1)
    }

    private func currentDayIndex(for trip: Trip) -> Int {
        guard let first = state.plan.first?.startsAt else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: first, to: now).day ?? 0
        return max(1, days + 1)
    }

    // MARK: - Formatting

    private func timeString(_ date: Date, tz: TimeZone) -> String {
        let f = DateFormatter()
        f.timeZone = tz
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    private func timeRange(_ event: PlanEvent) -> String {
        let start = timeString(event.startsAt, tz: event.displayTimeZone)
        let abbr = event.displayTimeZone.abbreviation() ?? ""
        if let end = event.endsAt {
            return "\(start) — \(timeString(end, tz: event.displayTimeZone)) \(abbr)"
        }
        return "\(start) \(abbr)"
    }

    private func remainingString(until date: Date) -> String {
        let interval = Int(date.timeIntervalSince(now))
        guard interval > 0 else { return "00:00" }
        let h = interval / 3600
        let m = (interval % 3600) / 60
        return String(format: "%02d:%02d", h, m)
    }

    private func countdown(to date: Date) -> String {
        let interval = Int(date.timeIntervalSince(now))
        guard interval > 0 else { return "NOW" }
        let h = interval / 3600
        let m = (interval % 3600) / 60
        if h >= 1 { return String(format: "IN %dH %02dM", h, m) }
        return String(format: "IN %dM", max(m, 1))
    }

    private func routeText(_ trip: Trip) -> String {
        "\(airportCode(trip.originTimeZoneId)) → \(airportCode(trip.destinationTimeZoneId))"
    }

    private func airportCode(_ tzId: String) -> String {
        // Best-effort: take last path component, take first 3 letters uppercased.
        // Real airport-code mapping is out of scope for this design pass.
        let last = tzId.split(separator: "/").last.map(String.init) ?? tzId
        let cleaned = last.replacingOccurrences(of: "_", with: "")
        return String(cleaned.prefix(3)).uppercased()
    }

    private func shiftText(_ trip: Trip) -> String {
        let shift = trip.timeZoneShiftHours
        if abs(shift) < 1 { return "SAME TZ" }
        let sign = shift > 0 ? "+" : "-"
        let h = Int(abs(shift).rounded())
        let dir = shift > 0 ? "ADVANCE" : "DELAY"
        return "\(sign)\(String(format: "%02d", h))H · \(dir)"
    }
}
