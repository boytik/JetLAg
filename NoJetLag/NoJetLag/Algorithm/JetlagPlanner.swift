import Foundation

/// Generates a personalized circadian-adjustment timeline for a trip, based on
/// a simplified Phase Response Curve (PRC).
///
/// **Important caveat:** this is a v1 / MVP heuristic. The real evidence base
/// (Czeisler, Burgess, Eastman) is more nuanced. The plan recommends consulting
/// a chronobiologist before treating these recommendations as medical advice.
///
/// ### Mental model
/// The user's body is a clock anchored to their origin schedule. A full
/// "phase shift" of magnitude H hours moves the body H hours ahead of (advance)
/// or behind (delay) home time. Each protocol day, the body shifts up to
/// `maxShiftPerDayHours`.
///
/// ### Round trips
/// When the trip has a return leg, the planner picks one of three strategies
/// based on the time spent at destination:
/// - **stay-anchored** (<3 days): don't shift; keep home schedule.
/// - **partial** (3–6 days): shift only as far as time at destination allows.
/// - **full** (≥7 days, or one-way): full delta in both directions.
///
/// The return leg mirrors the outbound logic with reversed direction, anchored
/// on `returnDeparture`.
struct JetlagPlanner {
    let trip: Trip
    let sleep: SleepSchedule

    enum Direction {
        case advance
        case delay
    }

    /// Maximum daily phase shift the body can comfortably absorb.
    static let maxShiftPerDayHours: Double = 1.5
    /// Days of pre-flight preparation before each leg.
    static let preflightDays: Int = 2

    // MARK: - Public entry point

    func makePlan() -> [PlanEvent] {
        var events: [PlanEvent] = [outboundFlightEvent()]
        let magnitude = trip.plannedShiftHours

        if magnitude >= 1.0 {
            events.append(contentsOf: outboundShiftEvents(magnitude: magnitude))
        } else if case .stayAnchored = trip.shiftStrategy {
            events.append(contentsOf: stayAnchoredAtDestinationEvents())
        }

        if trip.isRoundTrip {
            if let ret = returnFlightEvent() {
                events.append(ret)
            }
            if magnitude >= 1.0 {
                events.append(contentsOf: returnShiftEvents(magnitude: magnitude))
            }
            // stay-anchored: home schedule already covered by stayAnchoredAtDestinationEvents
        }

        return events.sorted { $0.startsAt < $1.startsAt }
    }

    // MARK: - Outbound shift

    /// Body shifts from phase 0 → ±magnitude over preflight + post-arrival days.
    private func outboundShiftEvents(magnitude: Double) -> [PlanEvent] {
        let outboundDelta = trip.timeZoneShiftHours
        let direction: Direction = outboundDelta > 0 ? .advance : .delay
        let shiftSign: Double = direction == .advance ? -1 : 1
        let postArrivalDays = max(1, min(6, Int(ceil(magnitude / Self.maxShiftPerDayHours))))

        let originCal = calendar(in: trip.originTimeZone)
        let originAnchor = originCal.startOfDay(for: trip.departure)

        var events: [PlanEvent] = []

        for dayIndex in (-Self.preflightDays)...postArrivalDays {
            // Cumulative shift achieved by the start of this day.
            let cumShift = min(
                magnitude,
                Double(max(0, dayIndex + Self.preflightDays)) * Self.maxShiftPerDayHours
            )

            // Body's "23:00" in HOME wall-clock at this point in the protocol.
            // Advance: bedtime moves earlier in home time → bedtime - cumShift.
            // Delay:   bedtime moves later   in home time → bedtime + cumShift.
            let bedHourRaw = sleep.bedtimeHour + shiftSign * cumShift

            guard let bedtimeDate = absoluteBedtime(bedHourRaw: bedHourRaw,
                                                   relativeDayIndex: dayIndex,
                                                   anchor: originAnchor,
                                                   calendar: originCal)
            else { continue }

            events.append(contentsOf: dailyEvents(
                bedtimeDate: bedtimeDate,
                direction: direction,
                sleepNote: outboundSleepNote(dayIndex: dayIndex)
            ))
        }

        return events
    }

    // MARK: - Return shift

    /// Body shifts from phase ±magnitude → 0 over preflight + post-return days.
    /// Direction is the OPPOSITE of the outbound direction.
    private func returnShiftEvents(magnitude: Double) -> [PlanEvent] {
        guard let returnDep = trip.returnDeparture else { return [] }

        let outboundDelta = trip.timeZoneShiftHours
        let returnDirection: Direction = outboundDelta > 0 ? .delay : .advance
        // outboundPhaseSign represents the body's residual phase relative to
        // home at the start of the return protocol: +1 if outbound was advance
        // (body is ahead of home), -1 if outbound was delay.
        let outboundPhaseSign: Double = outboundDelta > 0 ? 1 : -1

        let postReturnDays = max(1, min(6, Int(ceil(magnitude / Self.maxShiftPerDayHours))))

        let originCal = calendar(in: trip.originTimeZone)
        let returnAnchor = originCal.startOfDay(for: returnDep)

        var events: [PlanEvent] = []

        for dayIndex in (-Self.preflightDays)...postReturnDays {
            // Cumulative *reverse* shift: 0 at -preflightDays, magnitude at end.
            let cumReverse = min(
                magnitude,
                Double(max(0, dayIndex + Self.preflightDays)) * Self.maxShiftPerDayHours
            )
            // Residual phase at start of this day (signed).
            let phase = outboundPhaseSign * (magnitude - cumReverse)

            // Bedtime in home wall-clock = sleep.bedtimeHour - phase.
            let bedHourRaw = sleep.bedtimeHour - phase

            guard let bedtimeDate = absoluteBedtime(bedHourRaw: bedHourRaw,
                                                   relativeDayIndex: dayIndex,
                                                   anchor: returnAnchor,
                                                   calendar: originCal)
            else { continue }

            events.append(contentsOf: dailyEvents(
                bedtimeDate: bedtimeDate,
                direction: returnDirection,
                sleepNote: returnSleepNote(dayIndex: dayIndex)
            ))
        }

        return events
    }

    // MARK: - Stay-anchored mode (short round trips, <3 days at destination)

    /// Generates simple home-schedule sleep + caffeine events covering the
    /// entire destination stay. No light/melatonin events — body stays on
    /// home time so the user just powers through.
    private func stayAnchoredAtDestinationEvents() -> [PlanEvent] {
        guard let returnDep = trip.returnDeparture else { return [] }

        let originCal = calendar(in: trip.originTimeZone)
        let arrivalDayStart = originCal.startOfDay(for: trip.arrival)

        // Generate up to 7 days of home-schedule events covering [arrival, returnDeparture].
        var events: [PlanEvent] = []
        for dayOffset in 0...7 {
            guard let dayDate = originCal.date(byAdding: .day, value: dayOffset, to: arrivalDayStart) else { continue }
            let bedtimeDate = setHour(sleep.bedtimeHour, on: dayDate, calendar: originCal)
            let wakeDate = bedtimeDate.addingTimeInterval(sleep.sleepDurationHours * 3600)

            // Only include if bedtime falls inside the destination-stay window.
            guard bedtimeDate >= trip.arrival, bedtimeDate < returnDep else { continue }

            events.append(makeEvent(
                kind: .sleep, startsAt: bedtimeDate, endsAt: wakeDate,
                note: "Stay on home time — short trip."
            ))
            events.append(makeEvent(
                kind: .wake, startsAt: wakeDate, endsAt: nil, note: nil
            ))

            let caffeineCutoff = bedtimeDate.addingTimeInterval(-6 * 3600)
            events.append(makeEvent(
                kind: .caffeineAvoid, startsAt: caffeineCutoff, endsAt: bedtimeDate,
                note: "Cut caffeine at least 6 hours before bedtime."
            ))
        }
        return events
    }

    // MARK: - Per-day event bundle (sleep + light + melatonin + caffeine)

    private func dailyEvents(
        bedtimeDate: Date,
        direction: Direction,
        sleepNote: String?
    ) -> [PlanEvent] {
        let wakeDate = bedtimeDate.addingTimeInterval(sleep.sleepDurationHours * 3600)
        let cbtDate  = wakeDate.addingTimeInterval(-2 * 3600)

        var events: [PlanEvent] = [
            makeEvent(kind: .sleep, startsAt: bedtimeDate, endsAt: wakeDate, note: sleepNote),
            makeEvent(kind: .wake, startsAt: wakeDate, endsAt: nil, note: nil)
        ]

        switch direction {
        case .advance:
            events.append(contentsOf: advanceEvents(
                bedtimeDate: bedtimeDate, wakeDate: wakeDate, cbtDate: cbtDate
            ))
        case .delay:
            events.append(contentsOf: delayEvents(
                bedtimeDate: bedtimeDate, wakeDate: wakeDate
            ))
        }

        let caffeineCutoff = bedtimeDate.addingTimeInterval(-6 * 3600)
        events.append(makeEvent(
            kind: .caffeineAvoid,
            startsAt: caffeineCutoff, endsAt: bedtimeDate,
            note: "Cut caffeine at least 6 hours before bedtime."
        ))

        return events
    }

    /// ADVANCE direction (body needs to move earlier):
    ///   • Bright morning light right after waking pulls the clock earlier.
    ///   • Dim evening light right before bedtime prevents pushing back.
    ///   • Low-dose melatonin a few hours before bed accelerates the advance.
    private func advanceEvents(bedtimeDate: Date, wakeDate: Date, cbtDate: Date) -> [PlanEvent] {
        let lightStart = wakeDate
        let lightEnd   = wakeDate.addingTimeInterval(3 * 3600)
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

    /// DELAY direction (body needs to move later):
    ///   • Evening bright light before bed pushes the clock later.
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

    // MARK: - Date math

    /// Convert a (possibly out-of-range) bedtime hour into an absolute Date by
    /// folding the day-overflow into a calendar-day offset.
    private func absoluteBedtime(
        bedHourRaw: Double,
        relativeDayIndex: Int,
        anchor: Date,
        calendar cal: Calendar
    ) -> Date? {
        let dayOffset = Int(floor(bedHourRaw / 24))
        let normalizedBedHour = bedHourRaw - Double(dayOffset) * 24

        guard let bedAnchorDay = cal.date(
            byAdding: .day,
            value: relativeDayIndex + dayOffset,
            to: anchor
        ) else { return nil }

        return setHour(normalizedBedHour, on: bedAnchorDay, calendar: cal)
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

    // MARK: - Flight events

    private func outboundFlightEvent() -> PlanEvent {
        PlanEvent(
            kind: .flight,
            startsAt: trip.departure,
            endsAt: trip.arrival,
            timeZoneId: trip.destinationTimeZoneId,
            note: trip.name
        )
    }

    private func returnFlightEvent() -> PlanEvent? {
        guard let depart = trip.returnDeparture, let arrive = trip.returnArrival else { return nil }
        return PlanEvent(
            kind: .flight,
            startsAt: depart,
            endsAt: arrive,
            timeZoneId: trip.originTimeZoneId,
            note: "Return — \(trip.name)"
        )
    }

    // MARK: - Display TZ helper

    /// Tags an event with the right display TZ based on where the user is at
    /// `startsAt`:
    ///   • before outbound arrival           → origin
    ///   • between outbound arrival and
    ///     return arrival (or trip.arrival
    ///     for one-way trips)                → destination
    ///   • after return arrival (round trip) → origin
    private func makeEvent(
        kind: PlanEventKind,
        startsAt: Date,
        endsAt: Date?,
        note: String?
    ) -> PlanEvent {
        let tzId: String
        if let returnArrival = trip.returnArrival, startsAt >= returnArrival {
            tzId = trip.originTimeZoneId
        } else if startsAt >= trip.arrival {
            tzId = trip.destinationTimeZoneId
        } else {
            tzId = trip.originTimeZoneId
        }
        return PlanEvent(
            kind: kind,
            startsAt: startsAt,
            endsAt: endsAt,
            timeZoneId: tzId,
            note: note
        )
    }

    // MARK: - Per-day notes

    private func outboundSleepNote(dayIndex: Int) -> String? {
        switch dayIndex {
        case -Self.preflightDays..<0:
            return "Shift bedtime gradually toward your destination schedule."
        case 0:
            return "On the plane — try to align sleep with your destination night."
        default:
            return nil
        }
    }

    private func returnSleepNote(dayIndex: Int) -> String? {
        switch dayIndex {
        case -Self.preflightDays..<0:
            return "Shift bedtime back toward your home schedule."
        case 0:
            return "On the plane home — sleep aligned with your home night."
        default:
            return nil
        }
    }
}
