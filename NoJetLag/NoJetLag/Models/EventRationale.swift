import Foundation

/// A single peer-reviewed reference for an event's rationale.
struct Citation {
    let authors: String   // e.g. "Eastman & Burgess"
    let year: Int         // e.g. 2009
    let title: String     // article title
    let venue: String     // journal / book
    let url: String?      // optional DOI / link

    /// Short inline form: "Eastman & Burgess (2009)"
    var short: String { "\(authors) (\(year))" }
}

/// Why a particular event is on the schedule. Shown in the EventDetail sheet
/// when the user taps an event row or the active card.
struct EventRationale {
    let summary: String   // one-liner — shown inline on the active card
    let detail: String    // 1-3 short paragraphs explaining the mechanism
    let citation: Citation
}

extension PlanEventKind {
    /// Static rationale per event kind. The protocol direction (advance vs
    /// delay) is implicit from when the event is scheduled, so kind-only
    /// lookup is sufficient for v0.1.
    var rationale: EventRationale {
        switch self {
        case .seekLight:
            return EventRationale(
                summary: "Bright light now shifts your body clock toward the destination timezone.",
                detail: """
                Your circadian system is most sensitive to light around the lowest point of \
                your core body temperature (CBTmin) — typically 2-3 hours before your usual \
                wake time. Light AFTER CBTmin advances your phase (helps you sleep earlier \
                tomorrow); light BEFORE CBTmin delays it. We've timed this window to push \
                your phase in the right direction.

                Get outside if possible. Outdoor sunlight is roughly 50× brighter than \
                indoor lighting, even on cloudy days. Failing that: sit by a window or use \
                a 10,000-lux light therapy box for at least 30 minutes.
                """,
                citation: Citation(
                    authors: "Eastman & Burgess",
                    year: 2009,
                    title: "How to travel the world without jet lag",
                    venue: "Sleep Medicine Clinics 4(2): 241-255",
                    url: "https://doi.org/10.1016/j.jsmc.2009.02.006"
                )
            )

        case .avoidLight:
            return EventRationale(
                summary: "Bright light right now would shift your body clock the WRONG way.",
                detail: """
                Light hitting your eyes during this window pushes your circadian phase \
                opposite to where it needs to go. Even brief exposure — five minutes of \
                bright light — can undo a day of progress.

                Wear sunglasses outdoors. Dim screens or use night-shift mode. If you \
                can't avoid bright environments, blue-blocking glasses help. The goal \
                isn't pitch dark — just keep your eyes from receiving strong light \
                signals during this specific window.
                """,
                citation: Citation(
                    authors: "Khalsa et al.",
                    year: 2003,
                    title: "A phase response curve to single bright light pulses in human subjects",
                    venue: "Journal of Physiology 549(3): 945-952",
                    url: "https://doi.org/10.1113/jphysiol.2003.040477"
                )
            )

        case .takeMelatonin:
            return EventRationale(
                summary: "A small dose of melatonin now helps shift your sleep phase in the right direction.",
                detail: """
                Melatonin is a phase-shifting signal — not a sleep drug. Taken in your \
                biological evening, it advances your phase (helps you sleep earlier next \
                day). Taken in your biological morning, it delays it.

                Optimal dose for phase-shifting is 0.3-0.5 mg — NOT the 3-5 mg sold over \
                the counter. Research shows higher doses are no more effective for \
                phase-shifting and can cause grogginess the next day. Time matters more \
                than amount.

                ⚠ Melatonin is a prescription drug in some countries (incl. parts of \
                Europe and Russia). Check local rules and consult a clinician before \
                using it.
                """,
                citation: Citation(
                    authors: "Burgess et al.",
                    year: 2010,
                    title: "Sleep and circadian rhythm responses to small dose, evening melatonin",
                    venue: "Sleep 33(4): 481-487",
                    url: "https://doi.org/10.1093/sleep/33.4.481"
                )
            )

        case .sleep:
            return EventRationale(
                summary: "This is your target bedtime in the destination timezone.",
                detail: """
                The protocol shifts your sleep window earlier or later by roughly one \
                hour per day. That's the maximum your circadian system can adapt to \
                without breaking — push harder and you stress the system instead of \
                shifting it.

                A dark room, cool temperature (18-19°C / 64-66°F), and quiet help. If \
                you can't fall asleep within 20 minutes, get up briefly. Lying awake in \
                bed couples sleep with frustration, which makes the next night worse.
                """,
                citation: Citation(
                    authors: "Eastman & Burgess",
                    year: 2009,
                    title: "How to travel the world without jet lag",
                    venue: "Sleep Medicine Clinics 4(2): 241-255",
                    url: "https://doi.org/10.1016/j.jsmc.2009.02.006"
                )
            )

        case .wake:
            return EventRationale(
                summary: "Wake at this time to anchor the new schedule, even if last night was rough.",
                detail: """
                Your wake-up time is the strongest anchor your circadian system has. \
                Sleeping in to "catch up" after a poor night actively delays your \
                adjustment — the math doesn't favor you.

                Immediately after waking, get bright light (sunlight if you can). Hold \
                off on caffeine for the first 30-60 minutes; let cortisol rise naturally \
                before stacking caffeine on top of it.
                """,
                citation: Citation(
                    authors: "Czeisler et al.",
                    year: 1986,
                    title: "Bright light resets the human circadian pacemaker independent of the timing of the sleep-wake cycle",
                    venue: "Science 233(4764): 667-671",
                    url: "https://doi.org/10.1126/science.3726555"
                )
            )

        case .caffeineAvoid:
            return EventRationale(
                summary: "Caffeine now would still be in your system at bedtime.",
                detail: """
                Caffeine has a half-life of roughly 5-6 hours. A coffee at 5pm leaves \
                about half its dose still circulating at 11pm — long enough to fragment \
                your sleep architecture without you feeling "wired". You'll fall asleep \
                fine and still wake up unrefreshed.

                Rule of thumb: your last caffeine should be at least 8 hours before \
                your target bedtime.
                """,
                citation: Citation(
                    authors: "Drake et al.",
                    year: 2013,
                    title: "Caffeine effects on sleep taken 0, 3, or 6 hours before going to bed",
                    venue: "Journal of Clinical Sleep Medicine 9(11): 1195-1200",
                    url: "https://doi.org/10.5664/jcsm.3170"
                )
            )

        case .flight:
            return EventRationale(
                summary: "You're in the air — your circadian system is in transition.",
                detail: """
                What you do during the flight matters less than what comes immediately \
                before and after. Try to sleep on flights when it's nighttime at your \
                destination, stay awake when it's daytime there. Use eye mask and \
                earplugs aggressively. Hydrate.

                Don't reset your watch to destination time during the flight if it makes \
                you anxious about the schedule — focus on the protocol, not the local \
                clock.
                """,
                citation: Citation(
                    authors: "Eastman & Burgess",
                    year: 2009,
                    title: "How to travel the world without jet lag",
                    venue: "Sleep Medicine Clinics 4(2): 241-255",
                    url: "https://doi.org/10.1016/j.jsmc.2009.02.006"
                )
            )
        }
    }
}
