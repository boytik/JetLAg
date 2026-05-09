import SwiftUI
import Combine

/// Current/next-action card. The first thing the user opens during a trip.
struct NowView: View {
    @EnvironmentObject private var state: AppState
    @State private var now = Date()
    @State private var showingNewTrip = false
    @State private var explainingEvent: PlanEvent?
    @State private var showingFeedback = false

    private let ticker = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg0.ignoresSafeArea()
                Group {
                    if let trip = state.trip {
                        if trip.isCurrentlyInFlight(at: now) {
                            InFlightView(trip: trip, now: now)
                        } else {
                            content
                        }
                    } else {
                        emptyState
                    }
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
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
            .sheet(item: $explainingEvent) { ev in
                EventDetailView(event: ev)
            }
            .sheet(isPresented: $showingFeedback) {
                if let trip = state.trip {
                    FeedbackEntryView(trip: trip)
                }
            }
            .onReceive(ticker) { now = $0 }
        }
    }

    private var navTitle: String {
        if let trip = state.trip, trip.isCurrentlyInFlight(at: now) {
            return "IN FLIGHT"
        }
        return "NOW"
    }

    // MARK: - Subviews

    private var content: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                if shouldShowFeedbackCTA {
                    feedbackCTA
                }

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

    /// Show the feedback CTA after the user has landed and we don't have
    /// feedback for this trip yet.
    private var shouldShowFeedbackCTA: Bool {
        guard let trip = state.trip else { return false }
        guard now > trip.arrival else { return false }
        return !state.hasFeedback(for: trip.id)
    }

    private var feedbackCTA: some View {
        Button {
            showingFeedback = true
        } label: {
            InstrumentCard {
                HStack(alignment: .top, spacing: Spacing.md) {
                    Rectangle()
                        .fill(Color.amber)
                        .frame(width: 2)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("TRIP COMPLETE")
                            .font(Typography.mono(10, weight: .semibold))
                            .trackedUppercase(1.6)
                            .foregroundStyle(Color.amber)
                        Text("How did it go?")
                            .font(Typography.display(20, weight: .semibold))
                            .foregroundStyle(Color.textHi)
                        Text("Three questions. Stays on-device, optional email export.")
                            .font(Typography.body(12))
                            .foregroundStyle(Color.textMid)
                    }
                    Spacer()
                    Text("→")
                        .font(Typography.mono(15, weight: .semibold))
                        .foregroundStyle(Color.amber)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Cards

    private func activeCard(event: PlanEvent) -> some View {
        Button {
            explainingEvent = event
        } label: {
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

                    HStack(spacing: 4) {
                        Spacer()
                        Text("WHY THIS")
                            .font(Typography.mono(10, weight: .semibold))
                            .trackedUppercase(1.4)
                        Text("→")
                            .font(Typography.mono(11, weight: .semibold))
                    }
                    .foregroundStyle(Color.amber)
                    .padding(.top, Spacing.xs)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func nextCard(event: PlanEvent) -> some View {
        Button {
            explainingEvent = event
        } label: {
            InstrumentCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    SectionTag(
                        text: "NEXT UP",
                        color: Color.textLo,
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
                    HStack(spacing: 4) {
                        Spacer()
                        Text("WHY THIS")
                            .font(Typography.mono(10, weight: .semibold))
                            .trackedUppercase(1.4)
                        Text("→")
                            .font(Typography.mono(11, weight: .semibold))
                    }
                    .foregroundStyle(Color.amber)
                    .padding(.top, Spacing.xs)
                }
            }
        }
        .buttonStyle(.plain)
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
                                    Button {
                                        explainingEvent = ev
                                    } label: {
                                        EventRow(event: ev)
                                    }
                                    .buttonStyle(.plain)
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
        ScrollView {
            VStack(spacing: Spacing.lg) {
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
                .padding(.top, Spacing.xxl)
                .padding(.bottom, Spacing.sm)

                howItWorksCard

                Button {
                    showingNewTrip = true
                } label: {
                    Text("PLAN A TRIP")
                        .trackedUppercase(1.4)
                }
                .buttonStyle(.instrument)
                .padding(.top, Spacing.sm)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
    }

    private var howItWorksCard: some View {
        InstrumentCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionTag(text: "HOW IT WORKS")
                VStack(alignment: .leading, spacing: 0) {
                    stepRow(number: "01", text: "Add your flight — origin, destination, departure & arrival times.")
                    Hairline().padding(.vertical, Spacing.sm)
                    stepRow(number: "02", text: "We build your personal circadian shift: light, sleep, melatonin, caffeine windows.")
                    Hairline().padding(.vertical, Spacing.sm)
                    stepRow(number: "03", text: "Follow the day-by-day plan, starting two days before takeoff.")
                    Hairline().padding(.vertical, Spacing.sm)
                    stepRow(number: "04", text: "Share feedback in Settings — your trips help us tune the algorithm.")
                }
            }
        }
    }

    private func stepRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Text(number)
                .font(Typography.mono(13, weight: .semibold))
                .foregroundStyle(Color.amber)
                .frame(width: 24, alignment: .leading)
            Text(text)
                .font(Typography.body(14))
                .foregroundStyle(Color.textMid)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
            Spacer(minLength: 0)
        }
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
