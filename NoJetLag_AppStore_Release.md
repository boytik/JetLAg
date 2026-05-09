# NoJetLag — App Store Release Package

> One-stop document with everything you need to copy/paste into App Store Connect for the v1.0 submission. All copy is in English (US). Character limits noted next to each field. Voice follows `DESIGN.md` — direct, technical, terse. Pilot-watch, not wellness.
>
> **Bundle ID:** `asd.NoJetLag` *(rename to a verified domain like `dev.boytik.nojetlag` before submit)*
> **Version / Build:** `1.0` / `1`
> **Primary category:** Health & Fitness
> **Secondary category:** Travel
> **Age rating:** 4+ *(see §9 — melatonin reference is "Infrequent/Mild Medical Information")*
> **Pricing:** Subscription via Adapty *(or Free if you ship the paywall later — see §10)*
> **Devices:** iPhone only (iOS 16+)

---

## 1. App Name (max 30 characters)

**Primary:**

```
NoJetLag
```

`8 / 30` ✓

**Backups (in case the primary is taken on the store):**

- `NoJetLag · Sleep & Light` (24)
- `NoJetLag — Circadian` (20)
- `NoJetLag: Pilot Reset` (21)

> Apple does **not** allow words like *test*, *beta*, *trial*, *free*, or *#1* in the name. Avoid them everywhere on the listing.

---

## 2. Subtitle (max 30 characters)

**Primary:**

```
Land sharp from any timezone.
```

`29 / 30` ✓

**Backups:**

- `Personal circadian schedule.` (28)
- `Light, sleep, melatonin tuned.` (30)
- `Beat jet lag with light timing.` (30)

> The subtitle is heavily indexed by App Store search, so it's a second keyword surface — keep it descriptive, not a tagline.

---

## 3. Promotional Text (max 170 characters, can be edited after release without resubmission)

```
Personal jet lag protocol from your flight. Light, sleep, and melatonin timing tuned to your destination. Built for pilots and frequent travelers.
```

`148 / 170` ✓

**Backup variants:**

- *Round-trip emphasis:* `Round-trip protocol included. Short trips stay home-anchored, long trips fully shift. Built around peer-reviewed circadian science.` (139)
- *Privacy emphasis:* `Personalized light, sleep, and melatonin schedule from a single flight. Computed on-device. No account, no tracking.` (124)

---

## 4. Description (max 4000 characters)

> **Critical:** the very first paragraph MUST disclaim medical-advice status. App Review under Guideline 1.4.1 (Health Software & Medical Apps) checks this on anything that mentions melatonin, sleep, or circadian shift.

```
NoJetLag is general guidance based on circadian-rhythm research. It is not medical advice and not a medical device.

NoJetLag rebuilds your sleep, light exposure, and (optionally) melatonin schedule around the timezone you are flying into. Built for travelers whose first day matters: pilots, business travelers, executives, anyone who crosses four or more timezones and cannot afford to be foggy on landing day.

THREE LEVERS, ONE SCHEDULE
• Bright light at the right hour shifts your internal clock earlier or later. This is the dominant effect.
• Low-dose melatonin reinforces the shift if your country and your doctor allow it.
• A stepwise sleep window walks you to local time over the protocol days, instead of one painful night.

ROUND TRIPS DONE RIGHT
The protocol adapts to how long you stay at your destination:
• Under three days — your body stays anchored to home time. Round-trip shifts cost more than they pay back. We just protect your sleep.
• Three to six days — partial shift. Your body moves toward local time, but not all the way, so coming home is gentle.
• Seven days or more — full shift to destination, full shift back.

WHAT YOU GET
• Day-by-day timeline starting two days before takeoff
• Discrete events: light, avoid light, melatonin, sleep, wake, no caffeine
• "Right now" card on the home screen with what to do this hour and what comes next
• Calendar view of the whole protocol
• Optional ambient audio for focus and rest: rain, forest, cat
• Trip history and feedback to tune the algorithm over time
• No tracking SDKs other than the paywall provider; no advertising

PRIVATE BY DESIGN
• No account. No Apple ID linkage. No email required.
• Your sleep schedule, trip details, and feedback stay on your device.
• Recommendations are computed on-device from a single flight entry.
• See §"App Privacy" in the App Store listing for the full breakdown.

THE SCIENCE
The shift logic is informed by peer-reviewed research from Charles Czeisler (Harvard), Helen Burgess, and Charmane Eastman on circadian phase response curves, light therapy timing, and the role of low-dose melatonin in directional shifts. NoJetLag is a heuristic implementation, not a clinical instrument.

NOT MEDICAL ADVICE
NoJetLag does not prescribe medication. Melatonin availability and legal dose vary by country — in Russia and parts of the EU some doses are prescription-only, while in the United States it sells as a supplement. Consult a qualified healthcare professional before starting any melatonin protocol, particularly if you take prescription medication, are pregnant or breastfeeding, are under 18, or have a sleep, mood, or autoimmune condition.

WHO IT'S FOR
• Pilots, cabin crew, and frequent business travelers crossing four or more timezones
• Athletes and competitors traveling for events
• Anyone whose landing day cannot afford to be lost to fog
• People who prefer a structured protocol over a generic horoscope-style "you'll be tired"

REQUIREMENTS
NoJetLag needs internet on first launch only, to load the initial setup screens. After that, the app works fully offline; the timeline is computed locally on your device.

LAND SHARP
Open NoJetLag, enter your flight, follow the day-by-day plan. Light at the right hour, sleep windows that compress what would otherwise be five days of fog into a couple, and a calm interface that gets out of the way.
```

`~3,150 / 4000` ✓

---

## 5. Keywords (max 100 characters, comma-separated, NO spaces between)

> Don't repeat words from the App Name or Subtitle — App Store already indexes those. Don't include singular/plural duplicates.

```
jetlag,sleep,circadian,timezone,melatonin,light,traveler,pilot,flight,health,rhythm,wellness
```

`98 / 100` ✓

**Variants (pick one):**

- *Travel-leaning:* `jetlag,timezone,flight,travel,pilot,traveler,sleep,circadian,light,melatonin,protocol,reset` (96)
- *Health-leaning:* `jetlag,circadian,sleep,melatonin,light,timezone,health,wellness,rhythm,reset,traveler,protocol` (97)

> ⚠️ **Avoid these terms** — they get flagged by App Review or hurt ranking on a health-adjacent app: `cure, treatment, medical, diagnose, therapy, prescribed, doctor, drug, FDA, clinical, accurate, prophecy`.

---

## 6. What's New in This Version (max 4000 characters)

For the very first release:

```
Welcome to NoJetLag.

This is version 1.0. Enter your flight and we will build a personal day-by-day plan: when to seek bright light, when to dim screens, optional low-dose melatonin timing, sleep and wake windows, and caffeine cutoff times.

Round trips are supported. Short stays keep you on home time; long stays fully shift to destination and back.

Computed on your device. Not medical advice.
```

`~410 / 4000` ✓

For 1.1 onward, follow this pattern:

```
• Added [feature]
• Fixed [bug]
• Improved [thing]
• Translated to [language]
```

---

## 7. Support URL & Marketing URL & Privacy Policy URL

| Field             | Required? | What to put                                                           |
| ----------------- | --------- | --------------------------------------------------------------------- |
| Support URL       | Yes       | `https://nojetlag.app/support` (or a Notion page with `mailto:` + FAQ) |
| Marketing URL     | Optional  | `https://nojetlag.app`                                                |
| Privacy Policy URL| Yes       | `https://nojetlag.app/privacy` (Notion-published page is fine)        |

> If you don't want to buy a domain, Notion's `https://yourname.notion.site/...` URL works for both Privacy and Support. Apple has approved Notion-hosted policies many times. Reuse the `boytik@actvox.dev` mailbox you already use as the support address.

---

## 8. Privacy Nutrition Label (App Privacy in App Store Connect)

> NoJetLag uses **Adapty** for the onboarding flow and the paywall. Adapty does collect anonymous device-level data for attribution, install tracking, and subscription analytics. You **must** declare this in App Privacy or your build will be returned.

**Data Used to Track You:** None *(Adapty is configured without ad-attribution by default — confirm in your Adapty dashboard before submitting)*.

**Data Linked to You:** None *(no account, no email)*.

**Data Not Linked to You:**

- **Identifiers** → "Device ID"
  *Used by:* Adapty *(anonymous device ID for paywall + onboarding analytics)*
  *Reason:* App Functionality, Analytics
- **Usage Data** → "Product Interaction"
  *Used by:* Adapty *(onboarding screens viewed, paywall events)*
  *Reason:* App Functionality, Analytics
- **Diagnostics** → "Crash Data, Performance Data" *(only if you enable Apple's standard crash reporting — fine to leave OFF for v1.0)*

**Tracking permission (ATT):** Not requested. The app does not show ads and does not perform cross-app tracking.

> Trip data, sleep schedule, and feedback are stored on-device only and do **not** appear in the privacy label.

---

## 9. Age Rating Questionnaire — Recommended Answers

In App Store Connect → Age Rating, answer this way:

| Question                                                  | Answer                              |
| --------------------------------------------------------- | ----------------------------------- |
| Cartoon or Fantasy Violence                               | None                                |
| Realistic Violence                                        | None                                |
| Sexual Content or Nudity                                  | None                                |
| Profanity or Crude Humor                                  | None                                |
| Alcohol, Tobacco, or Drug Use or References              | **Infrequent/Mild** *(melatonin reference)* |
| Mature/Suggestive Themes                                  | None                                |
| Simulated Gambling                                        | None                                |
| Horror/Fear Themes                                        | None                                |
| Medical/Treatment Information                             | **Infrequent/Mild** *(circadian advice)* |
| Unrestricted Web Access                                   | No                                  |
| Gambling and Contests                                     | No                                  |
| Made for Kids                                             | No                                  |

**Resulting age rating:** **4+** *(or 12+ if Apple flags the medical-info answer — both are acceptable for this category).*

---

## 10. App Review Information — Reviewer Notes (max 4000 chars)

> This is the message Apple's reviewer reads first. Get ahead of every "health-adjacent app" rejection trigger here.

```
Hello App Review team,

Thank you for reviewing NoJetLag.

NoJetLag is a personalized circadian-shift schedule generated locally on the user's iPhone from a single flight entry. The app suggests the timing of three behavioral interventions — light exposure, sleep windows, and (optionally) low-dose melatonin — that are well-established in peer-reviewed circadian research (Czeisler, Burgess, Eastman). NoJetLag does not prescribe medication, does not collect health data, and is not a medical device.

WE ARE AWARE OF GUIDELINES 1.4.1 (HEALTH SOFTWARE) AND 5.1.1 (DATA COLLECTION) AND HAVE TAKEN THE FOLLOWING STEPS:

1. The first paragraph of the App Store description states explicitly:
   "NoJetLag is general guidance based on circadian-rhythm research. It is not medical advice and not a medical device."

2. The same disclaimer is shown:
   • On the onboarding screen on first launch, with a mandatory acknowledgment checkbox before the user can proceed (delivered via Adapty's onboarding builder, see "Adapty/AdaptyOnboardingPresenter.swift").
   • In Settings → IMPORTANT, accessible from the bottom tab bar at any time ("Views/SettingsView.swift" — `importantGroup`).
   • As an inline note on every melatonin event in the day-by-day plan ("0.3–0.5 mg low dose. Consult a doctor before starting.")

3. We do NOT use the words "cure", "treatment", "diagnose", "FDA", "clinically proven", "guaranteed", or any similar claims of medical certainty anywhere in the app, listing, or marketing.

4. Country-aware copy in Settings (`MelatoninLegality.swift`) reminds users in jurisdictions where higher-dose melatonin is prescription-only that they should consult a healthcare professional before purchasing.

CONTENT
The protocol logic is a heuristic implementation of the simplified Phase Response Curve. It is run entirely on-device. There is no AI, no LLM, no server-side personalization, and no remote configuration of medical recommendations.

ROUND TRIPS
For round trips shorter than three days at the destination, the planner deliberately suggests staying on home time and skips melatonin altogether — staying anchored is more conservative than a round-trip shift.

PRIVACY

• No account. No Apple ID linkage. No email collection.
• Trip data, sleep schedule, and feedback are stored ONLY on the user's device (JSON in the Documents directory).
• The app uses the Adapty SDK (https://adapty.io) to deliver the onboarding flow and (in future versions) the subscription paywall. Adapty receives an anonymous device identifier and onboarding-event analytics. This is declared in App Privacy under "Data Not Linked to You → Identifiers, Usage Data."
• No advertising SDK, no analytics SDK other than Adapty, no contact information collected.
• ITSAppUsesNonExemptEncryption is set to false in Info.plist (only standard HTTPS via Adapty).

INTERNET CONNECTIVITY

NoJetLag requires internet on the first launch only, to load the Adapty onboarding from the placement ID "Important". The app gates the entire UI behind this onboarding so users always see the medical disclaimer before any feature becomes accessible. Once onboarding is complete, the flag is persisted on-device and the app runs fully offline.

If the device is offline on first launch, NoJetLag presents a "CONNECTION REQUIRED" screen with a TRY AGAIN button — there is no way to bypass the onboarding.

DEMO ACCOUNT

No login is required to use the app. The reviewer can:

1. Launch the app on a device with internet.
2. Acknowledge the medical disclaimer on the Adapty onboarding (mandatory checkbox).
3. Set their bedtime and wake time on the native sleep-schedule sheet.
4. On the home screen tap PLAN A TRIP, enter origin and destination timezones plus departure and arrival times, and tap SAVE.
5. The day-by-day plan appears on the PLAN tab. Each event can be tapped to see the underlying explanation ("WHY THIS").
6. Settings includes ambient sound options, melatonin region info, and trip history.

There is no paid content gating any core feature in v1.0. *(Update this paragraph if you ship the paywall in 1.0.)*

CONTACT

If anything is unclear or you'd like additional information about the disclaimer flow or the source-code references above, please reach out at: boytik@actvox.dev

Thank you again for your time.

— The NoJetLag team
```

`~3,500 / 4000` ✓

> Replace the support email above if you set up a dedicated `support@nojetlag.app` mailbox.

---

## 11. Contact Information for App Review

Fill these on the same Reviewer screen:

- **First name:** *(your name)*
- **Last name:** *(your last name)*
- **Phone:** *(international format, e.g. +1 555 0100)*
- **Email:** `boytik@actvox.dev` *(or a dedicated support inbox)*

---

## 12. Export Compliance (in `Info.plist`)

Add this once and you can skip the encryption questionnaire on every release:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

Reason: NoJetLag only uses standard HTTPS (Adapty SDK over system TLS). It does not implement, contain, or expose any non-exempt cryptography.

---

## 13. Screenshots Plan (6.7" — iPhone 15 Pro Max — required)

Apple requires the **6.7" set** at minimum (1290 × 2796 px portrait). All other sizes are auto-derived. Aim for 5 to 6 screenshots, each with a one-line headline overlay matching the App Store voice.

| # | Screen                                  | Caption (≤30 chars on screenshot)        |
|---|-----------------------------------------|------------------------------------------|
| 1 | Now empty state with HOW IT WORKS card  | "Land sharp. Plan your flight."          |
| 2 | New Trip form with strategy preview     | "Round trips, done right."               |
| 3 | Plan timeline with OUTBOUND / RETURN    | "Day-by-day light and sleep."            |
| 4 | Right-now card showing seek-light event | "Tap to know what to do now."            |
| 5 | Settings with AMBIENCE and disclaimers  | "Private. On-device. Not medical advice."|
| 6 | *(Optional)* Calendar mode with dots    | "See the whole protocol at a glance."    |

> Screenshots must show the actual app UI. Don't add device frames in App Store Connect — Apple frames them automatically. Avoid showing UI text claiming medical accuracy. The amber-on-dark instrument aesthetic photographs well; do not switch to a brighter mock for marketing.

---

## 14. App Icon

- **Size:** 1024 × 1024 px PNG, **no alpha channel**, **no rounded corners** (Apple applies the mask).
- **Theme:** instrument / pilot-watch — geometric line art on dark `bg.0` with a single amber `#FFB000` accent. Think altimeter dial, sextant ring, or a stylized phase shift indicator. NOT a moon, NOT clouds, NOT a sleeping face — those read as "wellness category."
- **No text** on the icon. Apple discourages it and the app name is rendered below anyway.
- Generate via Figma, export to PNG. If you need to strip alpha: `pngcrush -rem alpha icon.png icon-final.png`.

---

## 15. Privacy Policy — Drop-in Text

> Paste this into a Notion page, publish to web (`Share → Publish → Publish to web`), and use the resulting URL in §7 above.

```
NoJetLag — Privacy Policy
Last updated: [DATE]

1. WHAT WE COLLECT
We do NOT collect personal data on our servers. Specifically:
• Your trip details, sleep schedule, and feedback are stored ONLY on your device, in app storage (JSON files in the Documents directory).
• A random anonymous device identifier is generated by the Adapty SDK (see section 3) on first launch. It is not linked to your Apple ID, name, email, or any other identity.

2. ON-DEVICE COMPUTATION
The day-by-day light, sleep, and melatonin schedule is computed entirely on your device from the flight you enter. No flight data, no sleep schedule, no feedback is transmitted to our servers or any third party.

3. THIRD-PARTY SERVICES
• Adapty (onboarding screens and subscription management): https://adapty.io/privacy/
  Adapty receives an anonymous device identifier and onboarding-event analytics in order to deliver the onboarding flow and manage subscription state. Adapty does not receive your trip details or sleep schedule.

4. CHILDREN'S PRIVACY
NoJetLag is not intended for users under 12 years of age. We do not knowingly collect personal data from children.

5. CHANGES TO THIS POLICY
We may update this policy as the app evolves. The "Last updated" date will reflect the most recent change.

6. CONTACT
Questions? Email us at boytik@actvox.dev.

7. DISCLAIMER
NoJetLag is general guidance based on circadian-rhythm research. It is not medical advice and not a medical device. Recommendations do not constitute medical, legal, financial, or psychological advice. Melatonin availability and legal dose vary by country — consult a qualified healthcare professional before starting any melatonin protocol.
```

---

## 16. Final Pre-Submit Checklist

In-app:

- [ ] Disclaimer "Not medical advice" in Adapty onboarding — covered via the strict-checkbox screen in `Onboarding_Copy.md` § "Screen 4 / 5"
- [ ] Same disclaimer in Settings → IMPORTANT — already in `Views/SettingsView.swift` ✓
- [ ] Inline melatonin notes on plan events — already in `Algorithm/JetlagPlanner.swift` ✓
- [ ] App icon 1024×1024 PNG, no alpha, no rounded corners
- [ ] 5–6 screenshots at 6.7" (iPhone 15 Pro Max simulator → Cmd+S)
- [ ] `ITSAppUsesNonExemptEncryption = false` in `Info.plist`
- [ ] Bundle ID matches App Store Connect entry (rename `asd.NoJetLag` → a real reverse-domain)
- [ ] Version `1.0`, build `1`
- [ ] Adapty live key in `NoJetLagApp.adaptyPublicKey` matches the production project
- [ ] Adapty placement `Important` is **Live** in the dashboard, not Draft

Backend / hosting:

- [ ] Adapty production API key configured
- [ ] Adapty paywall placement (if shipping in 1.0) is connected to a real subscription product in App Store Connect
- [ ] Domain set up (`nojetlag.app` or similar) — optional but cleaner than Notion subdomain
- [ ] Privacy Policy page live and reachable
- [ ] Support page live and reachable (or `mailto:` link works)

App Store Connect:

- [ ] App Name, Subtitle, Promotional Text, Description, Keywords, What's New all pasted from this doc
- [ ] Screenshots uploaded
- [ ] App Privacy nutrition label filled (Adapty data declared under "Data Not Linked to You")
- [ ] Age Rating set to 4+ or 12+ (whichever Apple's questionnaire produces)
- [ ] Reviewer Notes (Section 10) pasted with email confirmed
- [ ] Reviewer contact info filled
- [ ] Pricing: Free with Adapty paywall, OR Free with no IAP, OR paid — pick before submission and lock the on-device behavior accordingly

Then hit **Submit for Review** and wait 24–72 h. Land sharp.
