# NoJetLag — Project Notes for Claude

iPhone (SwiftUI) MVP. On-device. Builds a personalized circadian-shift schedule
(light, melatonin, sleep windows, caffeine cutoff) from a single flight.

Algorithm and product spec live in `jetlag_app_mvp_plan.md` (Russian).

## Design System

Always read `DESIGN.md` before making any visual or UI decisions.
All font choices, colors, spacing, radii, motion, and aesthetic direction are
defined there. Do not deviate without explicit user approval.

Direction: industrial / pilot-watch. Dark mode primary. IBM Plex Sans Condensed
+ IBM Plex Sans + IBM Plex Mono. Single amber accent (#FFB000). No illustrations,
no emojis, no SF Symbols (use custom geometric line icons).

In QA / review mode, flag any code that doesn't match `DESIGN.md` — including
default `.borderedProminent` buttons, default `Color(.systemGroupedBackground)`,
default 16pt corner radii, and SF Symbols.
