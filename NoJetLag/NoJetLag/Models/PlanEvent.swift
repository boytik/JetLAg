import Foundation

enum PlanEventKind: String, Codable, CaseIterable {
    case seekLight
    case avoidLight
    case takeMelatonin
    case sleep
    case wake
    case caffeineAvoid
    case flight

    var icon: String {
        switch self {
        case .seekLight:     return "sun.max.fill"
        case .avoidLight:    return "moon.fill"
        case .takeMelatonin: return "pills.fill"
        case .sleep:         return "bed.double.fill"
        case .wake:          return "alarm.fill"
        case .caffeineAvoid: return "cup.and.saucer"
        case .flight:        return "airplane"
        }
    }

    var title: String {
        switch self {
        case .seekLight:     return "Seek bright light"
        case .avoidLight:    return "Avoid bright light"
        case .takeMelatonin: return "Take melatonin"
        case .sleep:         return "Sleep"
        case .wake:          return "Wake up"
        case .caffeineAvoid: return "Avoid caffeine"
        case .flight:        return "Flight"
        }
    }
}

/// A single recommendation on the timeline.
struct PlanEvent: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var kind: PlanEventKind
    /// Absolute moment the event begins.
    var startsAt: Date
    /// Optional absolute moment the event ends.
    var endsAt: Date?
    /// The timezone the user is physically in for this event — controls how
    /// the time is rendered in the UI.
    var timeZoneId: String
    var note: String?

    var displayTimeZone: TimeZone {
        TimeZone(identifier: timeZoneId) ?? .current
    }
}
