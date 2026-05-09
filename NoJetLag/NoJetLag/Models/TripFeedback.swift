import Foundation

/// User-submitted feedback for one completed trip. Persisted locally in
/// `AppState.feedbackHistory`. Carries a snapshot of the trip's route and
/// shift so the entry survives even after the user clears the active trip.
struct TripFeedback: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var tripId: UUID
    var createdAt: Date

    // Snapshot of trip data — frozen at submission time.
    var routeOriginTZ: String
    var routeDestinationTZ: String
    var shiftHours: Double
    var arrivalDate: Date

    // Ratings on a 1...5 dot scale.
    var sleepDay1: Int
    var manageability: Int
    var overall: Int

    var comments: String

    /// Mean of the three ratings, useful for sorting / display.
    var averageRating: Double {
        Double(sleepDay1 + manageability + overall) / 3.0
    }

    /// "DPS → NRT" style header drawn from the snapshot.
    var routeShortText: String {
        "\(Self.airportCode(routeOriginTZ)) → \(Self.airportCode(routeDestinationTZ))"
    }

    /// "Bali → Tokyo" style header drawn from the snapshot.
    var routeLongText: String {
        "\(Self.cityName(routeOriginTZ)) → \(Self.cityName(routeDestinationTZ))"
    }

    var shiftText: String {
        if abs(shiftHours) < 1 { return "Same TZ" }
        let sign = shiftHours > 0 ? "+" : "-"
        let h = String(format: "%.1f", abs(shiftHours))
        let dir = shiftHours > 0 ? "advance" : "delay"
        return "\(sign)\(h)h \(dir)"
    }

    static func airportCode(_ tzId: String) -> String {
        let last = tzId.split(separator: "/").last.map(String.init) ?? tzId
        let cleaned = last.replacingOccurrences(of: "_", with: "")
        return String(cleaned.prefix(3)).uppercased()
    }

    static func cityName(_ tzId: String) -> String {
        tzId.split(separator: "/").last
            .map { String($0).replacingOccurrences(of: "_", with: " ") }
            ?? tzId
    }
}

extension TripFeedback {
    init(trip: Trip,
         sleepDay1: Int,
         manageability: Int,
         overall: Int,
         comments: String,
         createdAt: Date = Date())
    {
        self.id = UUID()
        self.tripId = trip.id
        self.createdAt = createdAt
        self.routeOriginTZ = trip.originTimeZoneId
        self.routeDestinationTZ = trip.destinationTimeZoneId
        self.shiftHours = trip.timeZoneShiftHours
        self.arrivalDate = trip.arrival
        self.sleepDay1 = sleepDay1
        self.manageability = manageability
        self.overall = overall
        self.comments = comments
    }
}

/// App-wide constants for reaching the developer.
enum NoJetLagContact {
    static let feedbackEmail = "manuelwentz11@icloud.com"
    static let appVersion = "0.1"
    static let appBuild = "MVP"
}
