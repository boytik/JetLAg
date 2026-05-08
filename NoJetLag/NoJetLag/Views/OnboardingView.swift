import SwiftUI

/// One-time onboarding: ask the user about their usual sleep schedule.
struct OnboardingView: View {
    @EnvironmentObject private var state: AppState
    @State private var bedtime: Date = Self.makeTime(hour: 23, minute: 0)
    @State private var wake: Date    = Self.makeTime(hour: 7, minute: 0)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    card {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Usual sleep schedule")
                                .font(.headline)

                            HStack {
                                Label("Bedtime", systemImage: "moon.fill")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                            Divider()
                            HStack {
                                Label("Wake up", systemImage: "alarm.fill")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                DatePicker("", selection: $wake, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                        }
                    }

                    Text("This is the only personal data we need to start. Everything is computed and stored locally on your device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button(action: complete) {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.tint)
                .padding(.bottom, 8)
            Text("Welcome to NoJetLag")
                .font(.largeTitle.weight(.semibold))
            Text("A personal light-and-sleep schedule that helps your body re-sync to a new timezone.")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
