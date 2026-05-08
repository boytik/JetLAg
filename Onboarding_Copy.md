# Onboarding Copy — NoJetLag (Adapty, English)

> Source-of-truth for the Adapty onboarding flow. Paste field-by-field into the
> Adapty Onboarding Builder. Voice and casing rules below come from `DESIGN.md`.

---

## Voice rules (read first)

- **Direct, technical, terse.** Pilot-watch energy, not wellness.
- **Imperative for actions** ("Reset your clock", "Continue"). Sentence case for body.
- **UPPERCASE + tracked** for status tags and CTAs (e.g. `SETUP · 02 / 05`, `BEGIN`).
- **No emojis. No exclamation marks. No "let's" / "we're so excited".**
- Single amber accent (`#FFB000`) for active CTA, progress dot, checkbox checkmark.
- Headlines end with a period.
- Body copy: max 3 short paragraphs per screen; ≤ 60 words total.

---

## Flow at a glance

| # | Screen | Purpose | CTA |
|---|---|---|---|
| 1 | Hook | One-line value prop | BEGIN |
| 2 | How it works | The three levers (light, melatonin, sleep) | CONTINUE |
| 3 | Personalization | Capture usual bedtime + wake | SAVE |
| 4 | Medical disclaimer | Hard gate with checkbox before paywall | CONTINUE |
| 5 | Paywall | Adapty product cards + value prop | START FREE TRIAL |

> **Notifications permission is NOT in onboarding.** Ask later, contextually,
> after the user creates their first trip ("We'll nudge you at 06:30 — Allow?").
> Higher acceptance, less friction here.

> **Personalization is mandatory** — disable any "Skip" option. The planner
> needs bedtime + wake to compute CBTmin. If you must allow skip, default to
> 23:00 / 07:00 silently.

---

## Screen 1 / 5 — Hook

| Adapty field | Value |
|---|---|
| Header tag | `SETUP · 01 / 05` |
| Title | Reset your clock. |
| Subtitle | A personal circadian schedule from your flight. |
| Body | NoJetLag rebuilds your sleep, light, and melatonin schedule around the timezone you're flying into. Built for travelers whose first day matters. |
| Primary CTA | `BEGIN` |
| Secondary CTA | — |
| Image | Minimal: a single thin amber line crossing the screen at an angle. No illustrations. |

---

## Screen 2 / 5 — How it works

| Adapty field | Value |
|---|---|
| Header tag | `SETUP · 02 / 05` |
| Title | Three levers, one schedule. |
| Subtitle | Light. Melatonin. Sleep windows. |
| Body (use as bullet list if Adapty supports it; else paragraph) | Bright light at the right hour shifts your internal clock earlier or later — the dominant effect. Low-dose melatonin reinforces the shift, if your country and doctor allow it. A stepwise sleep window walks you to local time over the protocol days, instead of one painful night. |
| Primary CTA | `CONTINUE` |
| Secondary CTA | — |
| Image | Three thin geometric icons stacked vertically (sun outline / pill outline / crescent outline) — 1.5 px stroke, amber. |

> Optional shorter variant if 60-word limit is hit:
> Body: "Light at the right hour shifts your clock. Low-dose melatonin reinforces the shift, if your doctor agrees. A stepwise sleep window walks you to local time."

---

## Screen 3 / 5 — Personalization

| Adapty field | Value |
|---|---|
| Header tag | `SETUP · 03 / 05` |
| Title | When do you usually sleep at home? |
| Subtitle | We use this to anchor your circadian phase. |
| Body | Two times. We don't read Apple Health, your location, or any account. Everything stays on this device. |
| Input 1 | Bedtime — time picker, default 23:00 |
| Input 2 | Wake up — time picker, default 07:00 |
| Primary CTA | `SAVE` |
| Secondary CTA | — |
| Image | None. The two inputs are the visual content. |

> If Adapty doesn't natively support time pickers in onboarding, fall back to a
> small list of presets: `EARLY · 22:00 / 06:00`, `STANDARD · 23:00 / 07:00`,
> `LATE · 00:30 / 08:30`. Capture exact times in the native app on first launch.

---

## Screen 4 / 5 — Medical disclaimer (mandatory acknowledgment)

| Adapty field | Value |
|---|---|
| Header tag | `SETUP · 04 / 05` |
| Title | This app is not medical advice. |
| Subtitle | Especially around melatonin. |
| Body | NoJetLag suggests timing for light exposure, sleep, and — if you choose — melatonin. It does not prescribe. |
| Body (continued, second paragraph) | Melatonin availability and legal dose vary by country. In Russia and parts of the EU, the doses commonly cited online are prescription-only. In the US, the same compound sells over the counter as a supplement. We do not endorse any specific dose. |
| Body (continued, third paragraph) | Before starting any melatonin protocol — even at low dose — consult a qualified healthcare professional. Especially if you take prescription medication, are pregnant or breastfeeding, are under 18, or have a sleep, mood, or autoimmune condition. |
| Checkbox label (required) | I understand. NoJetLag is not a substitute for medical advice. I will consult a healthcare professional before taking melatonin. |
| Primary CTA | `CONTINUE` — **disabled until checkbox ticked** |
| Secondary CTA | — |
| Image | Single amber outline triangle (warning glyph), 1.5 px stroke. No fill. |

### Tighter alternate (if the Adapty body field is short)

> Title: This app is not medical advice.
> Body: NoJetLag suggests timing for light, sleep, and optional melatonin. It does not prescribe.
>
> Melatonin laws and dosage rules differ by country. In Russia and much of the EU, common doses are prescription-only. In the US, melatonin sells as a supplement.
>
> Talk to a qualified healthcare professional before starting melatonin — especially if you take other medication, are pregnant, are under 18, or have a sleep, mood, or autoimmune condition.
>
> Checkbox: I understand. I will consult a doctor before taking melatonin.
> CTA: CONTINUE (disabled until ticked)

### Even tighter (single short paragraph + checkbox)

> Title: Before we start.
> Body: NoJetLag is general guidance based on circadian science. It is not medical advice. Melatonin laws and doses vary by country. Always consult a qualified healthcare professional before taking any supplement.
>
> Checkbox: I understand and want to continue.
> CTA: BEGIN (disabled until ticked)

> **Recommended:** the full version above. The disclaimer carries real legal
> weight (App Store guideline 1.4.1 + EU MDR for any health-tech-adjacent app)
> and the audience is serious enough to read it.

---

## Screen 5 / 5 — Paywall

> Built in Adapty's Paywall Builder — copy below is for the cards Adapty
> renders above the price options.

| Adapty field | Value |
|---|---|
| Header tag | `NOJETLAG PRO` |
| Title | Stay sharp on landing day. |
| Subtitle | Unlimited trips. Full timeline. Push notifications at the right hour. |
| Feature bullet 1 | Personalized light, sleep and melatonin schedule per flight |
| Feature bullet 2 | Push notifications timed to your circadian shift |
| Feature bullet 3 | Unlimited trips, all timezones, all directions |
| Feature bullet 4 | On-device — no account, no data collection |
| Primary CTA (e.g. annual) | `START FREE TRIAL` |
| Secondary CTA (e.g. monthly) | `Continue monthly` |
| Restore link | Restore purchase |
| Footer fine print | NoJetLag is not medical advice. Recommendations are based on circadian science. Consult a qualified healthcare professional before taking melatonin. Subscription auto-renews until cancelled in the App Store. |

---

## Post-onboarding contextual prompt — Notifications ask

Trigger: first time the user finishes the New Trip form and lands on the Plan
screen. Show a single sheet (not Adapty — native).

| Field | Value |
|---|---|
| Header tag | `ONE LAST STEP` |
| Title | We'll nudge you at the right hour. |
| Subtitle | Three to six prompts per protocol day. |
| Body | A timeline alone is passive. Notifications turn it into something you can actually follow on a moving day. |
| Primary CTA | `ALLOW NOTIFICATIONS` (triggers `UNUserNotificationCenter.requestAuthorization`) |
| Secondary CTA | `Not now` |

---

## Decisions for you to confirm

1. **Country-aware disclaimer.** The native `MelatoninLegality.current` callout
   tailors copy by region. Adapty is mostly static. Recommend keeping the
   generic disclaimer above in Adapty, and re-surfacing the regional callout in
   `Settings → Important` and as an inline note next to melatonin events.
   _Alternative:_ build three Adapty variants (RU / EU / US) — more setup work.

2. **Length.** This is the 5-screen version. To collapse to 4, merge screens 1
   and 2: the Hook becomes "Reset your clock. Three levers — light, melatonin,
   sleep windows." and screen 2 disappears.

3. **Skip on personalization.** Recommend disabling. If you keep it, default
   silently to 23:00 / 07:00 and surface the same prompt in Settings.

4. **Paywall trial.** Adapty supports free trial → paid. Decide trial length
   (7 / 14 days) and pricing tiers — that copy lives in Adapty's Paywall
   Builder, not here.

5. **Russian localization.** The current app is English-only. If you launch in
   RU too, mirror this file as `Onboarding_Copy_RU.md` — translation needs the
   same terse register, which is non-trivial to preserve.
