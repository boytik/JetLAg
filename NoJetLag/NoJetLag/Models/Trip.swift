import Foundation

/// A flight from one timezone to another at specific moments in time.
/// May optionally include a return leg, which turns this into a round trip
/// and changes the planner's strategy (full / partial / stay-anchored).
struct Trip: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var originTimeZoneId: String
    var destinationTimeZoneId: String
    /// Absolute moment of outbound departure.
    var departure: Date
    /// Absolute moment of outbound arrival.
    var arrival: Date
    /// Optional: absolute moment of return-leg departure (from destination).
    var returnDeparture: Date?
    /// Optional: absolute moment of return-leg arrival (back home).
    var returnArrival: Date?

    var originTimeZone: TimeZone {
        TimeZone(identifier: originTimeZoneId) ?? .current
    }

    var destinationTimeZone: TimeZone {
        TimeZone(identifier: destinationTimeZoneId) ?? .current
    }

    /// Hours of difference (destination - origin) at the moment of arrival.
    /// Positive = travelling east (advance phase), negative = travelling west (delay phase).
    /// Already accounts for daylight savings on the relevant dates.
    var timeZoneShiftHours: Double {
        let originSeconds = Double(originTimeZone.secondsFromGMT(for: arrival))
        let destSeconds = Double(destinationTimeZone.secondsFromGMT(for: arrival))
        var delta = (destSeconds - originSeconds) / 3600
        // Prefer the "shorter way around the globe" — your circadian system doesn't
        // care which direction you flew, only how far it has to shift.
        if delta > 12 { delta -= 24 }
        if delta < -12 { delta += 24 }
        return delta
    }

    /// Human-readable trip name, e.g. "Moscow → Bali".
    static func defaultName(for origin: String, destination: String) -> String {
        let originCity = origin.split(separator: "/").last.map(String.init)?
            .replacingOccurrences(of: "_", with: " ") ?? origin
        let destCity = destination.split(separator: "/").last.map(String.init)?
            .replacingOccurrences(of: "_", with: " ") ?? destination
        return "\(originCity) → \(destCity)"
    }

    // MARK: - Flight state

    /// True while `now` is between scheduled departure and arrival.
    func isCurrentlyInFlight(at now: Date = Date()) -> Bool {
        now >= departure && now < arrival
    }

    /// Total scheduled flight duration in seconds (>= 0).
    var flightDurationSeconds: TimeInterval {
        max(0, arrival.timeIntervalSince(departure))
    }

    /// Progress of the flight as a fraction 0..1, or nil if `now` is outside
    /// the flight window. Useful for progress bars.
    func flightProgress(at now: Date = Date()) -> Double? {
        guard isCurrentlyInFlight(at: now) else { return nil }
        let total = flightDurationSeconds
        guard total > 0 else { return nil }
        let elapsed = now.timeIntervalSince(departure)
        return min(1, max(0, elapsed / total))
    }

    /// Time remaining to landing (in seconds), or nil if not in flight.
    func timeToLanding(at now: Date = Date()) -> TimeInterval? {
        guard isCurrentlyInFlight(at: now) else { return nil }
        return max(0, arrival.timeIntervalSince(now))
    }

    // MARK: - Round trip

    /// True if both return-leg fields are set and form a valid window.
    var isRoundTrip: Bool {
        guard let depart = returnDeparture, let arrive = returnArrival else { return false }
        return depart > arrival && arrive >= depart
    }

    /// Whole days (rounded down) the user is at the destination, or nil for one-way.
    var daysAtDestination: Int? {
        guard isRoundTrip, let returnDep = returnDeparture else { return nil }
        let interval = returnDep.timeIntervalSince(arrival)
        guard interval > 0 else { return 0 }
        return Int(interval / 86400)
    }

    /// True while `now` is between scheduled return-leg departure and arrival.
    func isCurrentlyOnReturnFlight(at now: Date = Date()) -> Bool {
        guard let depart = returnDeparture, let arrive = returnArrival else { return false }
        return now >= depart && now < arrive
    }

    /// True if the user is "at destination" — between outbound arrival and
    /// (for round trips) return departure.
    func isAtDestination(at now: Date = Date()) -> Bool {
        guard now >= arrival else { return false }
        if let depart = returnDeparture {
            return now < depart
        }
        return true
    }

    // MARK: - Shift strategy
    //
    // For round trips, the trip's duration determines whether to fully shift,
    // partially shift, or stay home-anchored. Based on Eastman/Burgess
    // recommendations:
    //   • <3 days at destination → don't shift; staying on home time costs
    //     less circadian disruption than a full out-and-back shift.
    //   • 3–6 days → partial shift; cap so the body has time to come back.
    //   • ≥7 days → full shift, then full shift back on return.
    enum ShiftStrategy: Equatable {
        case stayAnchored
        case partial(magnitudeHours: Double)
        case full
    }

    var shiftStrategy: ShiftStrategy {
        guard let days = daysAtDestination else { return .full }
        if days < 3 { return .stayAnchored }
        if days < 7 {
            let full = abs(timeZoneShiftHours)
            // Use roughly half the destination stay for shifting, the other
            // half for "settled" days, leaving a similar window for returning.
            let halfMax = Double(days) * 1.5 / 2.0
            return .partial(magnitudeHours: min(full, halfMax))
        }
        return .full
    }

    /// The magnitude (hours) of phase shift the planner should aim for.
    var plannedShiftHours: Double {
        switch shiftStrategy {
        case .stayAnchored:           return 0
        case .partial(let hours):     return hours
        case .full:                   return abs(timeZoneShiftHours)
        }
    }
}
