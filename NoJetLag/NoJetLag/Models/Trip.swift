import Foundation

/// A flight from one timezone to another at specific moments in time.
struct Trip: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var originTimeZoneId: String
    var destinationTimeZoneId: String
    /// Absolute moment of departure.
    var departure: Date
    /// Absolute moment of arrival.
    var arrival: Date

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
}
