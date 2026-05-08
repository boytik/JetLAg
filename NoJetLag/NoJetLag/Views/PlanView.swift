import SwiftUI

/// Day-grouped timeline of all events in the active trip's plan.
struct PlanView: View {
    @EnvironmentObject private var state: AppState
    @State private var showingNewTrip = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg0.ignoresSafeArea()
                if state.trip == nil {
                    EmptyTripState { showingNewTrip = true }
                } else {
                    timeline
                }
            }
            .navigationTitle("PLAN")
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
        }
    }

    private var timeline: some View {
        let groups = groupedByDay(state.plan)
        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                ForEach(groups, id: \.id) { group in
                    daySection(group)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
    }

    private func daySection(_ group: DayGroup) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(group.dayTitle)
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.textLo)
                Spacer()
                Text(group.tzAbbr)
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
                        ForEach(Array(group.events.enumerated()), id: \.element.id) { idx, ev in
                            EventRow(event: ev)
                            if idx < group.events.count - 1 {
                                Hairline()
                            }
                        }
                    }
                }
                .frame(minHeight: 40)
            }
        }
    }

    // MARK: - Grouping

    private struct DayGroup {
        let id: String
        let dayTitle: String
        let tzAbbr: String
        let events: [PlanEvent]
    }

    private func groupedByDay(_ events: [PlanEvent]) -> [DayGroup] {
        // Group by (timeZoneId, calendar day in that TZ).
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
                events: bucket.events
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
