import Foundation
import Combine

/// App-wide state container. Holds the user's sleep schedule, the active trip,
/// and persists everything to JSON in the Documents directory.
///
/// ### Onboarding gate flags
/// We split the original `hasCompletedOnboarding` into two: the user MUST see
/// the Adapty onboarding once (`hasSeenAdaptyOnboarding`) AND must set their
/// sleep schedule via the native sheet (`hasSetSleepSchedule`). The app is
/// gated until both are true.
final class AppState: ObservableObject {
    @Published var sleepSchedule: SleepSchedule {
        didSet { save() }
    }

    @Published var trip: Trip? {
        didSet { save() }
    }

    /// True once the Adapty onboarding has been viewed end-to-end. Sticky:
    /// the gate doesn't replay it on subsequent launches, even offline.
    @Published var hasSeenAdaptyOnboarding: Bool {
        didSet { save() }
    }

    /// True once the user has saved their bedtime + wake-up time via the
    /// post-Adapty native sheet.
    @Published var hasSetSleepSchedule: Bool {
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
         hasSeenAdaptyOnboarding: Bool = false,
         hasSetSleepSchedule: Bool = false,
         backgroundSound: BackgroundSound = .rain,
         backgroundVolume: Double = 0.6,
         feedbackHistory: [TripFeedback] = [])
    {
        self.sleepSchedule = sleepSchedule
        self.trip = trip
        self.hasSeenAdaptyOnboarding = hasSeenAdaptyOnboarding
        self.hasSetSleepSchedule = hasSetSleepSchedule
        self.backgroundSound = backgroundSound
        self.backgroundVolume = backgroundVolume
        self.feedbackHistory = feedbackHistory
    }

    /// Convenience: true only when the user is fully through both gates.
    var isFullyOnboarded: Bool {
        hasSeenAdaptyOnboarding && hasSetSleepSchedule
    }

    /// Reset both gate flags. **Only intended for QA / development use.**
    func resetOnboarding() {
        hasSetSleepSchedule = false
        hasSeenAdaptyOnboarding = false
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
    /// The legacy `hasCompletedOnboarding` is preserved for migration only.
    private struct Snapshot: Codable {
        var sleepSchedule: SleepSchedule
        var trip: Trip?
        // Legacy. Maps to: hasSetSleepSchedule = true, hasSeenAdaptyOnboarding = false.
        var hasCompletedOnboarding: Bool?
        var hasSeenAdaptyOnboarding: Bool?
        var hasSetSleepSchedule: Bool?
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

        // ---- Migration: old `hasCompletedOnboarding` ----
        // Existing users who already saw the legacy native onboarding kept
        // their sleep schedule but were never shown Adapty — force them
        // through Adapty once.
        let legacyCompleted = snap.hasCompletedOnboarding ?? false
        let migratedSleepFlag = snap.hasSetSleepSchedule ?? legacyCompleted
        let migratedAdaptyFlag = snap.hasSeenAdaptyOnboarding ?? false

        return AppState(
            sleepSchedule: snap.sleepSchedule,
            trip: snap.trip,
            hasSeenAdaptyOnboarding: migratedAdaptyFlag,
            hasSetSleepSchedule: migratedSleepFlag,
            backgroundSound: snap.backgroundSound ?? .rain,
            backgroundVolume: snap.backgroundVolume ?? 0.6,
            feedbackHistory: snap.feedbackHistory ?? []
        )
    }

    func save() {
        let snap = Snapshot(
            sleepSchedule: sleepSchedule,
            trip: trip,
            hasCompletedOnboarding: nil,    // legacy field — no longer written
            hasSeenAdaptyOnboarding: hasSeenAdaptyOnboarding,
            hasSetSleepSchedule: hasSetSleepSchedule,
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
