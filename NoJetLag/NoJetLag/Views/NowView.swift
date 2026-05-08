import SwiftUI

/// Current/next-action card. The first thing the user opens during a trip.
struct NowView: View {
    @EnvironmentObject private var state: AppState
    @State private var now = Date()
    @State private var showingNewTrip = false

    private let ticker = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Group {
                if state.trip == nil {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle("Now")
            .sheet(isPresented: $showingNewTrip) {
                NewTripView()
            }
            .onReceive(ticker) { now = $0 }
        }
    }

    // MARK: - Subviews

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let current = state.currentEvent(at: now) {
                    bigCard(title: "Right now", event: current, accent: .tint)
                } else if let next = state.nextEvent(after: now) {
                    bigCard(title: countdown(to: next.startsAt), event: next, accent: .secondary)
                } else {
                    completionCard
                }

                if let trip = state.trip {
                    tripSummary(trip)
                }

                upcomingList
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func bigCard(title: String, event: PlanEvent, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: event.kind.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(accent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.kind.title)
                        .font(.title2.weight(.semibold))
                    Text(timeRange(event))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if let note = event.note {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var completionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ALL DONE")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("You've completed the protocol")
                .font(.title2.weight(.semibold))
            Text("Your circadian system should now be aligned with the destination timezone.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func tripSummary(_ trip: Trip) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "airplane")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.name)
                    .font(.subheadline.weight(.semibold))
                Text(directionText(for: trip))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var upcomingList: some View {
        let upcoming = state.plan.filter { $0.startsAt > now }.prefix(4)
        return Group {
            if !upcoming.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Coming up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                    VStack(spacing: 0) {
                        ForEach(Array(upcoming.enumerated()), id: \.element.id) { idx, ev in
                            EventRow(event: ev)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                            if idx < upcoming.count - 1 {
                                Divider().padding(.leading, 68)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.tint)
            Text("No active trip")
                .font(.title2.weight(.semibold))
            Text("Tell us about your flight to see what to do right now.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                showingNewTrip = true
            } label: {
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

    // MARK: - Formatting

    private func timeRange(_ event: PlanEvent) -> String {
        let fmt = DateFormatter()
        fmt.timeZone = event.displayTimeZone
        fmt.timeStyle = .short
        let start = fmt.string(from: event.startsAt)
        if let end = event.endsAt {
            return "\(start) – \(fmt.string(from: end))  \(event.displayTimeZone.abbreviation() ?? "")"
        }
        return "\(start)  \(event.displayTimeZone.abbreviation() ?? "")"
    }

    private func countdown(to date: Date) -> String {
        let interval = date.timeIntervalSince(now)
        guard interval > 0 else { return "Up next" }
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        if h >= 1 { return "In \(h)h \(m)m" }
        return "In \(max(m, 1))m"
    }

    private func directionText(for trip: Trip) -> String {
        let s = trip.timeZoneShiftHours
        if abs(s) < 1 { return "Same timezone" }
        let h = String(format: "%.1f", abs(s))
        return s > 0 ? "Eastward · advance \(h)h" : "Westward · delay \(h)h"
    }
}
