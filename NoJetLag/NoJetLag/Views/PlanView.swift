import SwiftUI

enum PlanMode: String, CaseIterable {
    case timeline, calendar
    var label: String {
        switch self {
        case .timeline: return "TIMELINE"
        case .calendar: return "CALENDAR"
        }
    }
}

/// Day-grouped plan: TIMELINE shows every day stacked; CALENDAR shows a month
/// grid with event indicators and the selected day's plan below.
struct PlanView: View {
    @EnvironmentObject private var state: AppState
    @State private var showingNewTrip = false
    @State private var explainingEvent: PlanEvent?
    @State private var mode: PlanMode = .timeline
    @State private var displayedMonth: Date = Date()
    @State private var selectedDay: Date?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg0.ignoresSafeArea()
                if state.trip == nil {
                    EmptyTripState { showingNewTrip = true }
                } else {
                    contentForMode
                }
            }
            .navigationTitle("PLAN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if state.trip != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingNewTrip = true
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundStyle(Color.amber)
                        }
                        .accessibilityLabel("Edit trip")
                    }
                }
            }
            .sheet(isPresented: $showingNewTrip) {
                NewTripView()
            }
            .sheet(item: $explainingEvent) { ev in
                EventDetailView(event: ev)
            }
            .onAppear(perform: hydrateCalendarSelection)
        }
    }

    @ViewBuilder
    private var contentForMode: some View {
        switch mode {
        case .timeline:
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    modeSwitcher
                    timelineMode
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
        case .calendar:
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    modeSwitcher
                    calendarMode
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
        }
    }

    // MARK: - Mode switcher

    private var modeSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(PlanMode.allCases, id: \.self) { m in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { mode = m }
                } label: {
                    Text(m.label)
                        .font(Typography.mono(10, weight: .semibold))
                        .trackedUppercase(1.6)
                        .foregroundStyle(mode == m ? Color.bg0 : Color.textLo)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(mode == m ? Color.amber : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.bg1)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    // MARK: - Timeline mode

    private var timelineMode: some View {
        let groups = groupedByDay(state.plan)
        return VStack(alignment: .leading, spacing: Spacing.lg) {
            ForEach(Array(groups.enumerated()), id: \.element.id) { idx, group in
                if shouldShowLegBanner(at: idx, in: groups) {
                    legBanner(group.leg)
                }
                daySection(title: group.dayTitle, tzAbbr: group.tzAbbr, events: group.events)
            }
        }
    }

    private func shouldShowLegBanner(at idx: Int, in groups: [DayGroup]) -> Bool {
        guard let leg = groups[idx].leg else { return false }
        if idx == 0 { return true }
        return groups[idx - 1].leg != leg
    }

    private func legBanner(_ leg: Leg?) -> some View {
        let label: String = {
            switch leg {
            case .outbound: return "OUTBOUND · TO DESTINATION"
            case .returning: return "RETURN · BACK HOME"
            case .none: return ""
            }
        }()
        return HStack(spacing: Spacing.sm) {
            Rectangle()
                .fill(Color.amber)
                .frame(width: 2, height: 18)
            Text(label)
                .font(Typography.mono(11, weight: .semibold))
                .trackedUppercase(1.6)
                .foregroundStyle(Color.amber)
            Spacer()
        }
        .padding(.top, Spacing.sm)
    }

    // Used to label OUTBOUND vs RETURN legs in round trips.
    private enum Leg: Equatable {
        case outbound
        case returning
    }

    private func leg(forEventStart start: Date) -> Leg? {
        guard let trip = state.trip, trip.isRoundTrip,
              let returnDep = trip.returnDeparture
        else { return nil }
        return start < returnDep ? .outbound : .returning
    }

    // MARK: - Calendar mode

    @ViewBuilder
    private var calendarMode: some View {
        monthHeader
        weekdayHeader
        monthGrid
        if let day = selectedDay {
            selectedDayPanel(for: day)
        } else {
            VStack(spacing: Spacing.sm) {
                Text("PICK A DAY")
                    .font(Typography.mono(11, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.textLo)
                Text("Tap any highlighted day above to see its plan.")
                    .font(Typography.body(13))
                    .foregroundStyle(Color.textMid)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.xl)
            .padding(.top, Spacing.lg)
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Text("‹")
                    .font(Typography.mono(20, weight: .medium))
                    .foregroundStyle(Color.amber)
                    .frame(width: 32, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.sm)
                            .stroke(Color.stroke, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            Text(monthTitle.uppercased())
                .font(Typography.display(22, weight: .semibold))
                .foregroundStyle(Color.textHi)
                .tracking(-0.3)

            Spacer()

            Button {
                shiftMonth(by: 1)
            } label: {
                Text("›")
                    .font(Typography.mono(20, weight: .medium))
                    .foregroundStyle(Color.amber)
                    .frame(width: 32, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.sm)
                            .stroke(Color.stroke, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var weekdayHeader: some View {
        let symbols = orderedWeekdaySymbols
        return HStack(spacing: 0) {
            ForEach(Array(symbols.enumerated()), id: \.offset) { _, sym in
                Text(sym.uppercased())
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.4)
                    .foregroundStyle(Color.textLo)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, Spacing.xs)
        .overlay(alignment: .bottom) { Hairline() }
    }

    private var monthGrid: some View {
        let cells = monthCells
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 56)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let cal = displayCalendar
        let events = eventsByDay[day] ?? []
        let dayNumber = cal.component(.day, from: day)
        let isToday = cal.isDateInToday(day)
        let isSelected = (selectedDay.map { cal.isDate($0, inSameDayAs: day) } ?? false)
        let hasEvents = !events.isEmpty

        let bgColor: Color = isSelected ? Color.amber.opacity(0.08) : (hasEvents ? Color.bg1 : Color.clear)
        let strokeColor: Color = isSelected ? Color.amber : (hasEvents ? Color.stroke : Color.stroke.opacity(0.3))
        let numberColor: Color = isSelected ? Color.amber : (hasEvents ? Color.textHi : Color.textLo.opacity(0.5))

        return Button {
            if hasEvents {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedDay = day
                }
            }
        } label: {
            VStack(spacing: 4) {
                HStack {
                    Text("\(dayNumber)")
                        .font(Typography.mono(13, weight: hasEvents ? .semibold : .regular))
                        .foregroundStyle(numberColor)
                    Spacer()
                    if isToday {
                        Circle()
                            .fill(Color.amber)
                            .frame(width: 4, height: 4)
                    }
                }
                Spacer(minLength: 0)
                eventDots(for: events)
            }
            .padding(6)
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .background(bgColor)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm)
                    .stroke(strokeColor, lineWidth: isSelected ? 1.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        }
        .buttonStyle(.plain)
        .disabled(!hasEvents)
    }

    private func eventDots(for events: [PlanEvent]) -> some View {
        let kinds = Array(Set(events.map { $0.kind })).prefix(4)
        return HStack(spacing: 3) {
            ForEach(Array(kinds), id: \.self) { kind in
                Circle()
                    .fill(dotColor(for: kind))
                    .frame(width: 4, height: 4)
            }
            Spacer(minLength: 0)
        }
    }

    private func dotColor(for kind: PlanEventKind) -> Color {
        switch kind {
        case .seekLight:     return Color.amber
        case .avoidLight:    return Color.advisoryRed
        case .takeMelatonin: return Color.sleepIndigo
        case .sleep:         return Color.sleepIndigo
        case .wake:          return Color.sleepIndigo
        case .caffeineAvoid: return Color.caffeineGreen
        case .flight:        return Color.textMid
        }
    }

    private func selectedDayPanel(for day: Date) -> some View {
        let events = (eventsByDay[day] ?? []).sorted { $0.startsAt < $1.startsAt }
        let title = selectedDayTitle(day)
        let tzAbbr = displayCalendar.timeZone.abbreviation() ?? ""
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            daySection(title: title, tzAbbr: tzAbbr, events: events)
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Shared day section (used by both modes)

    private func daySection(title: String, tzAbbr: String, events: [PlanEvent]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(title)
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.textLo)
                Spacer()
                Text(tzAbbr)
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.amber)
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xs)
            .overlay(alignment: .bottom) {
                Hairline()
            }

            InstrumentCard {
                HStack(alignment: .top, spacing: Spacing.md) {
                    AltitudeRule()
                        .frame(maxHeight: .infinity)
                    VStack(spacing: 0) {
                        ForEach(Array(events.enumerated()), id: \.element.id) { idx, ev in
                            Button {
                                explainingEvent = ev
                            } label: {
                                EventRow(event: ev)
                            }
                            .buttonStyle(.plain)
                            if idx < events.count - 1 {
                                Hairline()
                            }
                        }
                    }
                }
                .frame(minHeight: 40)
            }
        }
    }

    // MARK: - Calendar derivation

    /// Calendar configured for the destination timezone (or user's current TZ
    /// if there's no trip yet) plus the user's local week-start preference.
    private var displayCalendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = state.trip?.destinationTimeZone ?? .current
        c.firstWeekday = Calendar.current.firstWeekday
        return c
    }

    /// Map of "start of day" → events for that day.
    private var eventsByDay: [Date: [PlanEvent]] {
        let cal = displayCalendar
        var dict: [Date: [PlanEvent]] = [:]
        for event in state.plan {
            let day = cal.startOfDay(for: event.startsAt)
            dict[day, default: []].append(event)
        }
        return dict
    }

    /// 6×7 grid of dates for the displayed month. Cells outside the month are nil.
    private var monthCells: [Date?] {
        let cal = displayCalendar
        guard let interval = cal.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let firstOfMonth = interval.start

        let weekdayOfFirst = cal.component(.weekday, from: firstOfMonth) // 1=Sun…7=Sat
        let leadingEmpty = (weekdayOfFirst - cal.firstWeekday + 7) % 7

        let daysInMonth = cal.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30

        var cells: [Date?] = Array(repeating: nil, count: leadingEmpty)
        for offset in 0..<daysInMonth {
            if let d = cal.date(byAdding: .day, value: offset, to: firstOfMonth) {
                cells.append(cal.startOfDay(for: d))
            }
        }
        while cells.count < 42 {
            cells.append(nil)
        }
        return cells
    }

    private var orderedWeekdaySymbols: [String] {
        let cal = displayCalendar
        let symbols = cal.veryShortWeekdaySymbols // ["S","M","T","W","T","F","S"]
        let start = cal.firstWeekday - 1
        return Array(symbols[start...]) + Array(symbols[..<start])
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        f.timeZone = displayCalendar.timeZone
        return f.string(from: displayedMonth)
    }

    private func shiftMonth(by months: Int) {
        let cal = displayCalendar
        if let next = cal.date(byAdding: .month, value: months, to: displayedMonth) {
            displayedMonth = next
        }
    }

    private func selectedDayTitle(_ day: Date) -> String {
        let f = DateFormatter()
        f.timeZone = displayCalendar.timeZone
        f.dateFormat = "EEEE · dd MMM"
        return f.string(from: day).uppercased()
    }

    /// On first appearance, point the calendar at the trip's first day with
    /// events and pre-select today (if it has events) or that first day.
    private func hydrateCalendarSelection() {
        guard selectedDay == nil else { return }
        let cal = displayCalendar
        let allDays = eventsByDay.keys.sorted()
        guard let firstEventDay = allDays.first else { return }
        displayedMonth = firstEventDay

        let today = cal.startOfDay(for: Date())
        if eventsByDay[today] != nil {
            selectedDay = today
        } else {
            selectedDay = firstEventDay
        }
    }

    // MARK: - Timeline grouping (legacy, kept for TIMELINE mode)

    private struct DayGroup {
        let id: String
        let dayTitle: String
        let tzAbbr: String
        let events: [PlanEvent]
        let leg: Leg?
    }

    private func groupedByDay(_ events: [PlanEvent]) -> [DayGroup] {
        var buckets: [(key: String, dayTitle: String, tzAbbr: String, sort: Date, events: [PlanEvent])] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE · dd MMM"

        for event in events {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = event.displayTimeZone
            let dayStart = cal.startOfDay(for: event.startsAt)
            let key = "\(event.timeZoneId)|\(dayStart.timeIntervalSince1970)"
            formatter.timeZone = event.displayTimeZone
            let dayTitle = formatter.string(from: dayStart)
            let tzAbbr = event.displayTimeZone.abbreviation() ?? event.timeZoneId

            if let idx = buckets.firstIndex(where: { $0.key == key }) {
                buckets[idx].events.append(event)
            } else {
                buckets.append((key: key, dayTitle: dayTitle, tzAbbr: tzAbbr, sort: dayStart, events: [event]))
            }
        }
        buckets.sort { $0.sort < $1.sort }
        return buckets.enumerated().map { idx, bucket in
            DayGroup(
                id: bucket.key,
                dayTitle: "DAY \(String(format: "%02d", idx + 1)) · \(bucket.dayTitle.uppercased())",
                tzAbbr: bucket.tzAbbr,
                events: bucket.events,
                leg: leg(forEventStart: bucket.sort)
            )
        }
    }
}

private struct EmptyTripState: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            VStack(spacing: Spacing.sm) {
                Text("NO TRIP")
                    .font(Typography.mono(11, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.textLo)
                Text("Add your flight and we'll build a personal light, sleep and melatonin schedule.")
                    .font(Typography.body(15))
                    .foregroundStyle(Color.textMid)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            Button(action: onCreate) {
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
}
