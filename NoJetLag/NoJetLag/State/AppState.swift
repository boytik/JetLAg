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

    @Published var backgroundSound: BackgroundSound {
        didSet {
            AmbientPlayer.shared.play(backgroundSound)
            save()
        }
    }

    @Published var backgroundVolume: Double {
        didSet {
            AmbientPlayer.shared.volume = Float(backgroundVolume)
            save()
        }
    }

    @Published var feedbackHistory: [TripFeedback] {
        didSet { save() }
    }

    init(sleepSchedule: SleepSchedule = .default,
         trip: Trip? = nil,
         hasCompletedOnboarding: Bool = false,
         backgroundSound: BackgroundSound = .rain,
         backgroundVolume: Double = 0.6,
         feedbackHistory: [TripFeedback] = [])
    {
        self.sleepSchedule = sleepSchedule
        self.trip = trip
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.backgroundSound = backgroundSound
        self.backgroundVolume = backgroundVolume
        self.feedbackHistory = feedbackHistory
    }

    /// True if the user has already submitted feedback for the given trip.
    func hasFeedback(for tripId: UUID) -> Bool {
        feedbackHistory.contains { $0.tripId == tripId }
    }

    /// Boots the ambient player to match the current state. Call once at
    /// app launch (after `load()`).
    func startAmbiencePlayback() {
        AmbientPlayer.shared.volume = Float(backgroundVolume)
        AmbientPlayer.shared.play(backgroundSound)
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

    /// Persisted shape. New fields are optional so older snapshots still decode.
    private struct Snapshot: Codable {
        var sleepSchedule: SleepSchedule
        var trip: Trip?
        var hasCompletedOnboarding: Bool
        var backgroundSound: BackgroundSound?
        var backgroundVolume: Double?
        var feedbackHistory: [TripFeedback]?
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
            hasCompletedOnboarding: snap.hasCompletedOnboarding,
            backgroundSound: snap.backgroundSound ?? .rain,
            backgroundVolume: snap.backgroundVolume ?? 0.6,
            feedbackHistory: snap.feedbackHistory ?? []
        )
    }

    func save() {
        let snap = Snapshot(
            sleepSchedule: sleepSchedule,
            trip: trip,
            hasCompletedOnboarding: hasCompletedOnboarding,
            backgroundSound: backgroundSound,
            backgroundVolume: backgroundVolume,
            feedbackHistory: feedbackHistory
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
