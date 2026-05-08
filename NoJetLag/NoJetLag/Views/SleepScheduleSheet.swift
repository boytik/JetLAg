import SwiftUI

/// Native sleep-schedule capture, shown as a hard gate immediately after
/// Adapty onboarding completes.
///
/// This is a *full-screen* view (not a `.sheet`) so iOS can't dismiss it
/// with a swipe-down. The only path forward is `SAVE`, which writes the
/// times into `AppState` and flips `hasSetSleepSchedule = true`.
struct SleepScheduleSheet: View {
    let onComplete: () -> Void
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
                    midsleepCard
                    footnote
                    Button(action: complete) {
                        Text("SAVE")
                            .trackedUppercase(1.4)
                    }
                    .buttonStyle(.instrument)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.xxl)
                .padding(.bottom, Spacing.xl)
            }
        }
        .onAppear(perform: hydrate)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                PulsingDot(size: 6)
                Text("SETUP · STEP 02")
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.amber)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Your sleep schedule.")
                    .font(Typography.display(32, weight: .semibold))
                    .foregroundStyle(Color.textHi)
                    .tracking(-0.5)
                Text("Two times. We use them to anchor your circadian phase.")
                    .font(Typography.body(15))
                    .foregroundStyle(Color.textMid)
            }
        }
        .padding(.bottom, Spacing.sm)
    }

    private var scheduleCard: some View {
        InstrumentCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionTag(text: "USUAL SCHEDULE")
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

    private var midsleepCard: some View {
        HStack(spacing: Spacing.md) {
            Text("MIDSLEEP")
                .font(Typography.mono(10, weight: .semibold))
                .trackedUppercase(1.6)
                .foregroundStyle(Color.textLo)
            Spacer()
            Text(midsleepText)
                .font(Typography.mono(13, weight: .medium))
                .foregroundStyle(Color.amber)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.stroke, lineWidth: 1)
        )
    }

    private var footnote: some View {
        Text("All data stays on this device. No Apple Health, no location, no account.")
            .font(Typography.body(12))
            .foregroundStyle(Color.textLo)
    }

    // MARK: - Helpers

    private var midsleepText: String {
        let bedHour  = Self.decimalHour(from: bedtime)
        let wakeHour = Self.decimalHour(from: wake)
        var span = wakeHour - bedHour
        if span < 0 { span += 24 }
        var mid = bedHour + span / 2
        if mid >= 24 { mid -= 24 }
        let h = Int(mid)
        let m = Int(((mid - Double(h)) * 60).rounded())
        return String(format: "%02d:%02d", h, m)
    }

    private func hydrate() {
        // If the user has already saved a schedule before (e.g. via legacy
        // OnboardingView migration), seed the pickers from it.
        if state.hasSetSleepSchedule {
            bedtime = Self.timeFromHour(state.sleepSchedule.bedtimeHour)
            wake    = Self.timeFromHour(state.sleepSchedule.wakeHour)
        }
    }

    private func complete() {
        state.sleepSchedule = SleepSchedule(
            bedtimeHour: Self.decimalHour(from: bedtime),
            wakeHour:    Self.decimalHour(from: wake)
        )
        state.hasSetSleepSchedule = true
        onComplete()
    }

    private static func makeTime(hour: Int, minute: Int) -> Date {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
    }

    private static func timeFromHour(_ hour: Double) -> Date {
        var comps = DateComponents()
        comps.hour = Int(hour)
        comps.minute = Int(((hour - Double(Int(hour))) * 60).rounded())
        return Calendar.current.date(from: comps) ?? Date()
    }

    private static func decimalHour(from date: Date) -> Double {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60.0
    }
}
