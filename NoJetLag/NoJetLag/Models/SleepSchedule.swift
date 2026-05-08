import Foundation

/// The user's typical sleep window, described as hours of the day in their home timezone.
struct SleepSchedule: Codable, Equatable {
    /// Usual bedtime as decimal hour-of-day, e.g. 23.5 = 23:30.
    var bedtimeHour: Double
    /// Usual wake time as decimal hour-of-day.
    var wakeHour: Double

    static let `default` = SleepSchedule(bedtimeHour: 23.0, wakeHour: 7.0)

    /// Sleep duration in hours, accounting for crossing midnight.
    var sleepDurationHours: Double {
        let raw = wakeHour - bedtimeHour
        return raw >= 0 ? raw : raw + 24
    }

    /// Midsleep point as decimal hour-of-day. The most reliable circadian phase
    /// proxy without sensors.
    var midsleepHour: Double {
        let mid = bedtimeHour + sleepDurationHours / 2
        return mid.truncatingRemainder(dividingBy: 24)
    }

    /// Approximate Core Body Temperature minimum — the anchor of the Phase
    /// Response Curve. Roughly 2 hours before habitual wake.
    var cbtMinHour: Double {
        let cbt = wakeHour - 2.0
        return (cbt + 24).truncatingRemainder(dividingBy: 24)
    }
}
