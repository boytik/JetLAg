import Foundation
import Combine

/// App-wide state container. Holds the user's sleep schedule, the active trip,
/// and persists everything to JSON in the Documents directory.
final class AppState: ObservableObject {
    @Published var sleepSchedule: SleepSchedule {
        didSet { save() }
    }

    @Published var trip: Trip? {
        didSet { save() }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { save() }
    }

    init(sleepSchedule: SleepSchedule = .default,
         trip: Trip? = nil,
         hasCompletedOnboarding: Bool = false)
    {
        self.sleepSchedule = sleepSchedule
        self.trip = trip
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    /// The full event timeline, derived from the active trip + sleep schedule.
    var plan: [PlanEvent] {
        guard let trip else { return [] }
        return JetlagPlanner(trip: trip, sleep: sleepSchedule).makePlan()
    }

    /// The next upcoming event after `now`, or nil if the plan is finished.
    func nextEvent(after now: Date = Date()) -> PlanEvent? {
        plan.first { $0.startsAt > now }
    }

    /// The currently-active event (an event whose window contains `now`), or nil.
    func currentEvent(at now: Date = Date()) -> PlanEvent? {
        plan.first { event in
            guard let end = event.endsAt else { return false }
            return event.startsAt <= now && now < end
        }
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var sleepSchedule: SleepSchedule
        var trip: Trip?
        var hasCompletedOnboarding: Bool
    }

    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("nojetlag-state.json")
    }

    static func load() -> AppState {
        guard let data = try? Data(contentsOf: fileURL),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data)
        else {
            return AppState()
        }
        return AppState(
            sleepSchedule: snap.sleepSchedule,
            trip: snap.trip,
            hasCompletedOnboarding: snap.hasCompletedOnboarding
        )
    }

    func save() {
        let snap = Snapshot(
            sleepSchedule: sleepSchedule,
            trip: trip,
            hasCompletedOnboarding: hasCompletedOnboarding
        )
        do {
            let data = try JSONEncoder().encode(snap)
            try data.write(to: Self.fileURL, options: .atomic)
        } catch {
            #if DEBUG
            print("AppState.save failed: \(error)")
            #endif
        }
    }
}
