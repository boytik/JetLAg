import SwiftUI

/// Day-grouped timeline of all events in the active trip's plan.
struct PlanView: View {
    @EnvironmentObject private var state: AppState
    @State private var showingNewTrip = false

    var body: some View {
        NavigationStack {
            Group {
                if state.trip == nil {
                    EmptyTripState { showingNewTrip = true }
                } else {
                    timeline
                }
            }
            .navigationTitle("Plan")
            .toolbar {
                if state.trip != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingNewTrip = true
                        } label: {
                            Image(systemName: "pencil")
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
        return List {
            ForEach(groups, id: \.id) { group in
                Section {
                    ForEach(group.events) { event in
                        EventRow(event: event)
                    }
                } header: {
                    Text(group.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Grouping

    private struct DayGroup {
        let id: String
        let title: String
        let events: [PlanEvent]
    }

    private func groupedByDay(_ events: [PlanEvent]) -> [DayGroup] {
        // Group by (timeZoneId, calendar day in that TZ).
        var buckets: [(key: String, title: String, sort: Date, events: [PlanEvent])] = []
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none

        for event in events {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = event.displayTimeZone
            let dayStart = cal.startOfDay(for: event.startsAt)
            let key = "\(event.timeZoneId)|\(dayStart.timeIntervalSince1970)"
            formatter.timeZone = event.displayTimeZone
            let title = "\(formatter.string(from: dayStart))  •  \(event.displayTimeZone.abbreviation() ?? "")"

            if let idx = buckets.firstIndex(where: { $0.key == key }) {
                buckets[idx].events.append(event)
            } else {
                buckets.append((key: key, title: title, sort: dayStart, events: [event]))
            }
        }
        buckets.sort { $0.sort < $1.sort }
        return buckets.map { DayGroup(id: $0.key, title: $0.title, events: $0.events) }
    }
}

private struct EmptyTripState: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.tint)
            Text("No trip yet")
                .font(.title2.weight(.semibold))
            Text("Add your flight and we'll build a personal light, sleep and melatonin schedule.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            Button(action: onCreate) {
                Label("Plan a trip", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: 280)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
