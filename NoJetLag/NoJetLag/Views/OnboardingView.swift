import SwiftUI

/// One-time onboarding: ask the user about their usual sleep schedule.
struct OnboardingView: View {
    @EnvironmentObject private var state: AppState
    @State private var bedtime: Date = Self.makeTime(hour: 23, minute: 0)
    @State private var wake: Date    = Self.makeTime(hour: 7, minute: 0)

    var body: some View {
        ZStack {
            Color.bg0.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header
                    scheduleCard
                    footnote
                    Button(action: complete) {
                        Text("CONTINUE")
                            .trackedUppercase(1.4)
                    }
                    .buttonStyle(.instrument)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.xxl)
                .padding(.bottom, Spacing.xl)
            }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                PulsingDot(size: 6)
                Text("BOOT · v0.1")
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.amber)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("NoJetLag")
                    .font(Typography.display(36, weight: .semibold))
                    .foregroundStyle(Color.textHi)
                    .tracking(-0.5)
                Text("Personal circadian-shift schedule from your flight.")
                    .font(Typography.body(15))
                    .foregroundStyle(Color.textMid)
            }
        }
        .padding(.bottom, Spacing.sm)
    }

    private var scheduleCard: some View {
        InstrumentCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionTag(text: "Usual sleep schedule")
                    .padding(.bottom, Spacing.xs)

                HStack {
                    Text("Bedtime")
                        .font(Typography.body(15, weight: .medium))
                        .foregroundStyle(Color.textHi)
                    Spacer()
                    DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(Color.amber)
                }
                Hairline()
                HStack {
                    Text("Wake up")
                        .font(Typography.body(15, weight: .medium))
                        .foregroundStyle(Color.textHi)
                    Spacer()
                    DatePicker("", selection: $wake, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(Color.amber)
                }
            }
        }
    }

    private var footnote: some View {
        Text("This is the only personal data we need to start. Everything is computed and stored on-device.")
            .font(Typography.body(12))
            .foregroundStyle(Color.textLo)
    }

    private func complete() {
        state.sleepSchedule = SleepSchedule(
            bedtimeHour: Self.decimalHour(from: bedtime),
            wakeHour:    Self.decimalHour(from: wake)
        )
        state.hasCompletedOnboarding = true
    }

    private static func makeTime(hour: Int, minute: Int) -> Date {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
    }

    private static func decimalHour(from date: Date) -> Double {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60.0
    }
}
