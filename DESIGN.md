# Design System — NoJetLag

> Source of truth for all visual decisions. Read this before writing UI code.
> Direction: industrial / pilot-watch. Primary theme: dark.

## Product Context

- **What this is:** Native iPhone (SwiftUI) app that builds a personalized circadian-shift schedule from a single flight — light exposure, melatonin, sleep windows, caffeine windows.
- **Who it's for:** Serious frequent travelers — pilots, business travelers, executives who cross 4+ timezones and cannot afford to be off their game on day one.
- **Space/industry:** Travel utility / circadian science. Peers: Timeshifter, Flykitt, StopJetLag.
- **Project type:** Native iOS app (SwiftUI), MVP, on-device, no backend.
- **Memorable thing:** "This is for serious travelers." Pilot-watch energy. The app feels like an instrument, not a wellness brand.

## Aesthetic Direction

- **Direction:** Industrial / utilitarian / aviation-instrument
- **Decoration level:** Minimal — data is the design. No illustrations, no decorative shapes, no gradients beyond the active-card highlight.
- **Mood:** Calm, dense, mission-critical. Think Foreflight, Flighty, Garmin pilot watches. NOT Calm, NOT Headspace, NOT Timeshifter.
- **Reference:** competitors converged on "friendly wellness" (warm palettes, cute illustrations, rounded fonts). NoJetLag deliberately departs.

## Theme

- **Primary:** Dark mode. Users open this on planes, in hotels at night, in early-morning departure halls. Dark is the default, not the toggle.
- **Secondary:** Light mode (warm paper) — optional and supported, but the design is composed for dark first.

## Typography

Bundle the IBM Plex family in `Resources/Fonts/`. Register in `Info.plist` under `UIAppFonts`. Wrap in a SwiftUI `Font` extension (`Font.plexDisplay(_:)`, `Font.plexMono(_:)`).

- **Display / Hero / Big advice text:** `IBM Plex Sans Condensed`, weight 600, tracking -0.02em
- **Body / Paragraphs:** `IBM Plex Sans` 400, line-height 1.5–1.6. Fallback to SF Pro on systems where bundled fonts haven't loaded.
- **Data / Times / Airport codes / Countdowns / Timeline timestamps:** `IBM Plex Mono` 500, tracking +0.02em. Always tabular nums (the family ships with them).
- **System UI (nav titles, tab labels):** `IBM Plex Sans Condensed` 600 for nav titles, `IBM Plex Mono` 500 for tab labels (uppercase, tracked).

### Type Scale

| Role | Family | Size | Weight | Tracking |
| --- | --- | --- | --- | --- |
| Display | Plex Sans Condensed | 28-40pt | 600 | -0.02em |
| Title | Plex Sans Condensed | 22pt | 600 | -0.01em |
| Headline | Plex Sans | 17pt | 600 | 0 |
| Body | Plex Sans | 15-16pt | 400 | 0 |
| Footnote | Plex Sans | 13pt | 400 | 0 |
| Caption / Tag | Plex Mono | 10-11pt | 500 | +0.12em (uppercase) |
| Data large | Plex Mono | 28-32pt | 500 | -0.02em |
| Data small | Plex Mono | 12pt | 500 | +0.02em |

### Casing

UPPERCASE with tracked letter-spacing for: tab labels, status tags ("RIGHT NOW", "DAY 02 / 06"), badges (LIGHT / AVOID / SLEEP / CAF), section headers in timelines. Sentence case everywhere else.

## Color

Use Asset Catalog. Each color has a light + dark variant. Reference colors in code as `Color("bg.0")`, never hardcode hex.

### Dark (primary)

| Token | Hex | Role |
| --- | --- | --- |
| `bg.0` | `#0E1116` | Screen background (cockpit-night) |
| `bg.1` | `#161A22` | Elevated surface (cards, sheets) |
| `bg.2` | `#1D222C` | Inset / inactive controls |
| `stroke` | `#2A2F36` | Card borders, dividers |
| `stroke.strong` | `#3A4049` | Stronger borders, focused fields |
| `text.hi` | `#ECECEC` | Primary text |
| `text.mid` | `#B7BCC4` | Secondary text |
| `text.lo` | `#8A8F98` | Muted / metadata |

### Light

| Token | Hex | Role |
| --- | --- | --- |
| `bg.0` | `#F4F1EA` | Warm paper background |
| `bg.1` | `#FFFFFF` | Elevated surface |
| `stroke` | `#E0DCD2` | Borders |
| `text.hi` | `#1C1C1E` | Primary text |
| `text.mid` | `#4A4F58` | Secondary |
| `text.lo` | `#6E737B` | Muted |

### Accent (single)

| Token | Hex | Use |
| --- | --- | --- |
| `amber` | `#FFB000` | THE accent. Active "right now" advice card. Selected tab. Primary CTA. Used sparingly — never decorative. |
| `amber.dim` | `#B07700` | Pressed / dimmed amber |

### Semantic

| Token | Hex | Meaning |
| --- | --- | --- |
| `red` | `#E5484D` | "Avoid bright light" / warnings |
| `indigo` | `#5E6AD2` | Sleep events (bedtime, melatonin, wake) |
| `green` | `#46A758` | Caffeine ok / positive confirmation |

## Spacing

- **Base unit:** 4pt
- **Density:** Comfortable but tighter than iOS defaults — ~85% of system inset. Aviation tools are dense; we honor that without crowding.
- **Scale:** `4 / 8 / 12 / 16 / 24 / 32 / 48 / 64`

## Layout & Shape

- **Border radius scale:** small=4pt, medium=8pt. Do NOT use the iOS default 16pt — it reads as "soft consumer." Pills/circles only for status dots and the home-indicator area.
- **Card style:** 1px stroke `stroke` color, NO soft shadows. Active card uses 1px stroke in `amber` plus a 3px amber bar on the leading edge.
- **Timeline:** Thin 1px vertical rule on the leading edge with repeating 12pt tick marks (altitude-ruler motif). Each row gets a 8pt horizontal tick connector to the rule.
- **Tab bar:** 3 tabs (Now / Plan / Settings). Custom tab style — the standard iOS tab tint is replaced by the active label going from `text.lo` → `amber`. Icons are 1.5px stroke geometric (square with inner element), not SF Symbols (which read too "consumer iOS").
- **Nav bar:** No translucent material. Solid `bg.0`. Title in Plex Sans Condensed 26pt 600, right-aligned meta block in Plex Mono 10pt for status (e.g., "DAY 02 / 06 · ON TRACK").
- **Status bar:** System-default time on left. We don't customize.

## Iconography

- **Primary:** Custom 1.5px stroke geometric line icons (drawn in Swift `Path` or bundled SVG). Square outlines with inner shapes — instrument-panel feel.
- **Avoid:** Most SF Symbols. They are the visual fingerprint of "default iOS app" and they fight the IBM Plex typography. Exception: status bar / system overrides we cannot avoid.
- **Status dots:** 6pt amber circles for active state. A subtle 1Hz pulse animation (4% scale) on the active "right now" indicator.

## Motion

- **Easing:** `easeOut` for enter, `easeIn` for exit, `linear` for steady-state animations.
- **Duration:** micro 100ms · short 150ms · medium 200ms · long 300ms. No bouncy springs anywhere — they read as "fun" and we are not.
- **Signature gesture:** The active "RIGHT NOW" card pulses subtly (4% scale, 1Hz, ease-in-out). Same energy as the GPS-fix indicator on a pilot watch — alive, but not cute. Nothing else animates idly.

## Tone & Copy

- **Voice:** Direct, technical, terse. Imperative for actions ("Seek bright light", "Avoid bright light", "Take melatonin 0.5mg"). NOT chatty ("Time for a sunshine break! ☀️").
- **Casing:** UPPERCASE for status tags and the active advice headline. Sentence case for body and notes.
- **Numbers and codes:** Always in Plex Mono. Airport codes always 3 letters uppercase (DPS, NRT, JFK). Timezones as 3-letter abbreviations (JST, PST, BST). Phase shifts as `+8H` / `-5H`.
- **No emojis.** Ever. They are the visual signature of the wellness category we are leaving.

## Decisions Log

| Date | Decision | Rationale |
| --- | --- | --- |
| 2026-05-08 | Initial design system | Created via /design-consultation. Memorable thing: "for serious travelers." Direction: industrial / pilot-watch (visual language only — target user is the regular serious traveler, NOT pilots). Differentiates against Timeshifter (friendly-wellness), Flykitt (sunset-gradient), StopJetLag (legacy web). |
| 2026-05-08 | IBM Plex over SF Pro | Plex is a designed-together institutional family with built-in technical/serious feel. Bundling adds ~600KB and slight iOS-native friction; reward is instant "this is an instrument" recognition. |
| 2026-05-08 | Single amber accent (#FFB000) | Reads as instrument-panel "look here" warning amber. Distinct from every competitor (Timeshifter teal/orange, Flykitt sunset-pink). |
| 2026-05-08 | Custom geometric icons over SF Symbols | SF Symbols pair tightly with SF Pro and read as "default iOS" — fights our typography. Custom 1.5px stroke icons reinforce instrument-panel feel. |
| 2026-05-08 | 4-8pt corner radii (not 16pt) | Default iOS rounded-rect reads as "consumer soft." Smaller radii read as "engineered tool." |
| 2026-05-08 | v0.1 scope: iPhone target only | No Apple Watch app, no Widget extension target for v0.1. Single iPhone target keeps the MVP buildable solo. Watch / Lock-Screen widgets explicitly deferred to v0.2+. |
| 2026-05-08 | "Why this advice" pattern | Every PlanEvent is tappable and opens an `EventDetailView` sheet with: one-line summary, mechanism prose, peer-reviewed citation. Tap target shown via "WHY THIS →" affordance on Now-screen cards and full-row tap on Plan-timeline rows. Citations live in `Models/EventRationale.swift`. Adds the credibility a serious traveler needs. |
| 2026-05-08 | Feedback collection: local + email export | v0.1 feedback strategy: store ratings on-device, ship to dedicated mailbox `feedback@nojetlag.app` via system Share Sheet / `mailto:`. No backend in v0.1. Migrate to TelemetryDeck (anonymous opt-in analytics) once feedback patterns emerge. App copy stays English-only across v0.1. |
