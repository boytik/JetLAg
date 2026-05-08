import Foundation

/// Generates a personalized circadian-adjustment timeline for a trip, based on
/// a simplified Phase Response Curve (PRC).
///
/// **Important caveat:** this is a v1 / MVP heuristic. The real evidence base
/// (Czeisler, Burgess, Eastman) is more nuanced. The plan recommends consulting
/// a chronobiologist before treating these recommendations as medical advice.
///
/// ### Mental model
/// The user's body is a clock anchored to their origin schedule. Each protocol
/// day, that clock shifts by up to `maxShiftPerDayHours` toward the destination.
/// All recommendations are computed as **absolute Dates** anchored in the origin
/// timezone — the destination timezone only affects how those Dates are
/// displayed in the UI.
struct JetlagPlanner {
    let trip: Trip
    let sleep: SleepSchedule

    enum Direction {
        case advance   // travelling east — body must shift earlier
        case delay     // travelling west — body must shift later
        case none      // less than ~1h difference, no protocol needed
    }

    /// Maximum daily phase shift the body can comfortably absorb.
    static let maxShiftPerDayHours: Double = 1.5
    /// Days of pre-flight preparation.
    static let preflightDays: Int = 2

    var direction: Direction {
        let s = trip.timeZoneShiftHours
        if abs(s) < 1.0 { return .none }
        return s > 0 ? .advance : .delay
    }

    /// How many calendar days the post-arrival adjustment will span.
    var postArrivalDays: Int {
        let raw = Int(ceil(abs(trip.timeZoneShiftHours) / Self.maxShiftPerDayHours))
        return min(max(raw, 1), 6)
    }

    // MARK: - Public entry point

    func makePlan() -> [PlanEvent] {
        guard direction != .none else {
            return [flightEvent()]
        }

        var events: [PlanEvent] = [flightEvent()]
        let totalShift = abs(trip.timeZoneShiftHours)
        // Advance moves the body earlier → body's wall-clock landmarks move
        // earlier in absolute time → subtract the shift.
        let shiftSign: Double = direction == .advance ? -1 : 1
        let originCal = calendar(in: trip.originTimeZone)
        let originAnchor = originCal.startOfDay(for: trip.departure)

        for dayIndex in (-Self.preflightDays)...postArrivalDays {
            let cumShift = cumulativeShift(forDayIndex: dayIndex, total: totalShift)

            // Compute bedtime as an absolute Date in origin TZ.
            // bedtimeHour can shift past 0 or 24 — handle the wraparound.
            let bedHourRaw = sleep.bedtimeHour + shiftSign * cumShift
            let dayOffset = Int(floor(bedHourRaw / 24))
            let normalizedBedHour = bedHourRaw - Double(dayOffset) * 24

            guard let bedAnchorDay = originCal.date(
                byAdding: .day,
                value: dayIndex + dayOffset,
                to: originAnchor
            ) else { continue }

            let bedtimeDate = setHour(normalizedBedHour, on: bedAnchorDay, calendar: originCal)
            let wakeDate = bedtimeDate.addingTimeInterval(sleep.sleepDurationHours * 3600)
            let cbtDate  = wakeDate.addingTimeInterval(-2 * 3600)

            events.append(makeEvent(
                kind: .sleep,
                startsAt: bedtimeDate, endsAt: wakeDate,
                note: noteForSleep(dayIndex: dayIndex)
            ))
            events.append(makeEvent(
                kind: .wake,
                startsAt: wakeDate, endsAt: nil,
                note: nil
            ))

            switch direction {
            case .advance:
                events.append(contentsOf: advanceEvents(
                    bedtimeDate: bedtimeDate, wakeDate: wakeDate, cbtDate: cbtDate
                ))
            case .delay:
                events.append(contentsOf: delayEvents(
                    bedtimeDate: bedtimeDate, wakeDate: wakeDate
                ))
            case .none:
                break
            }

            // Caffeine cutoff: 6h before today's bedtime.
            let caffeineCutoff = bedtimeDate.addingTimeInterval(-6 * 3600)
            events.append(makeEvent(
                kind: .caffeineAvoid,
                startsAt: caffeineCutoff, endsAt: bedtimeDate,
                note: "Cut caffeine at least 6 hours before bedtime."
            ))
        }

        return events.sorted { $0.startsAt < $1.startsAt }
    }

    // MARK: - PRC event builders

    /// ADVANCE direction (eastward):
    ///   • Bright morning light (right after waking) pulls the clock earlier.
    ///   • Dim evening light (right before bedtime) prevents pushing back.
    ///   • Low-dose melatonin a few hours before bed accelerates the advance.
    private func advanceEvents(bedtimeDate: Date, wakeDate: Date, cbtDate: Date) -> [PlanEvent] {
        let lightStart = wakeDate                            // wake
        let lightEnd   = wakeDate.addingTimeInterval(3 * 3600) // wake + 3h
        let avoidStart = bedtimeDate.addingTimeInterval(-3 * 3600)
        let avoidEnd   = bedtimeDate
        let melatonin  = bedtimeDate.addingTimeInterval(-5 * 3600)

        return [
            makeEvent(kind: .seekLight, startsAt: lightStart, endsAt: lightEnd,
                      note: "Bright light (≥10 000 lux or sunshine) — pulls your clock earlier."),
            makeEvent(kind: .avoidLight, startsAt: avoidStart, endsAt: avoidEnd,
                      note: "Dim screens, blue-light blockers, low ambient light."),
            makeEvent(kind: .takeMelatonin, startsAt: melatonin, endsAt: nil,
                      note: "0.3–0.5 mg low dose. Consult a doctor before starting.")
        ]
    }

    /// DELAY direction (westward):
    ///   • Evening bright light (before bed) pushes the clock later.
    ///   • Dim morning light right after waking prevents pulling forward.
    ///   • Optional morning melatonin can support the delay.
    private func delayEvents(bedtimeDate: Date, wakeDate: Date) -> [PlanEvent] {
        let lightStart = bedtimeDate.addingTimeInterval(-4 * 3600)
        let lightEnd   = bedtimeDate.addingTimeInterval(-1 * 3600)
        let avoidStart = wakeDate
        let avoidEnd   = wakeDate.addingTimeInterval(2 * 3600)

        return [
            makeEvent(kind: .seekLight, startsAt: lightStart, endsAt: lightEnd,
                      note: "Evening bright light pushes your clock later."),
            makeEvent(kind: .avoidLight, startsAt: avoidStart, endsAt: avoidEnd,
                      note: "Sunglasses outdoors during this window."),
            makeEvent(kind: .takeMelatonin, startsAt: wakeDate, endsAt: nil,
                      note: "Optional 0.3 mg at wake. Consult a doctor first.")
        ]
    }

    // MARK: - Helpers

    private func flightEvent() -> PlanEvent {
        PlanEvent(
            kind: .flight,
            startsAt: trip.departure,
            endsAt: trip.arrival,
            timeZoneId: trip.destinationTimeZoneId,
            note: trip.name
        )
    }

    /// Cumulative shift in hours achieved by the start of a given day index.
    /// Pre-flight days (-2, -1) accumulate shift; departure day = 0; post-arrival
    /// days continue accumulating until total shift is reached.
    private func cumulativeShift(forDayIndex dayIndex: Int, total: Double) -> Double {
        let daysSinceShiftStart = max(0, dayIndex + Self.preflightDays)
        return min(total, Double(daysSinceShiftStart) * Self.maxShiftPerDayHours)
    }

    /// Wraps an event in the right display-timezone metadata. Events before
    /// arrival are shown in origin time; events at or after arrival are shown
    /// in destination time.
    private func makeEvent(
        kind: PlanEventKind,
        startsAt: Date,
        endsAt: Date?,
        note: String?
    ) -> PlanEvent {
        let tzId = startsAt < trip.arrival
            ? trip.originTimeZoneId
            : trip.destinationTimeZoneId
        return PlanEvent(
            kind: kind,
            startsAt: startsAt,
            endsAt: endsAt,
            timeZoneId: tzId,
            note: note
        )
    }

    private func calendar(in tz: TimeZone) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        return cal
    }

    private func setHour(_ hour: Double, on date: Date, calendar cal: Calendar) -> Date {
        let h = max(0, min(23, Int(hour)))
        let m = max(0, min(59, Int(((hour - Double(Int(hour))) * 60).rounded())))
        return cal.date(bySettingHour: h, minute: m, second: 0, of: date) ?? date
    }

    private func noteForSleep(dayIndex: Int) -> String? {
        switch dayIndex {
        case -Self.preflightDays..<0:
            return "Shift bedtime gradually toward your destination schedule."
        case 0:
            return "On the plane — try to align sleep with your destination night."
        default:
            return nil
        }
    }
}
