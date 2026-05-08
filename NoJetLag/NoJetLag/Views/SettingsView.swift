import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState
    @State private var bedtime: Date = Date()
    @State private var wake: Date    = Date()
    @State private var showingClearAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg0.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        sleepGroup
                        tripGroup
                        importantGroup
                        versionGroup
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xl)
                }
            }
            .navigationTitle("SETTINGS")
            .alert("Clear trip?", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) { state.trip = nil }
            } message: {
                Text("Your sleep schedule will be kept.")
            }
            .onAppear(perform: hydrate)
        }
    }

    // MARK: Groups

    private var sleepGroup: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionTag(text: "SLEEP SCHEDULE")
                .padding(.horizontal, Spacing.xs)

            InstrumentCard(padding: 0) {
                VStack(spacing: 0) {
                    settingRow(label: "Bedtime") {
                        DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .tint(Color.amber)
                            .onChange(of: bedtime) { newValue in
                                state.sleepSchedule.bedtimeHour = Self.decimalHour(from: newValue)
                            }
                    }
                    Hairline()
                    settingRow(label: "Wake up") {
                        DatePicker("", selection: $wake, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .tint(Color.amber)
                            .onChange(of: wake) { newValue in
                                state.sleepSchedule.wakeHour = Self.decimalHour(from: newValue)
                            }
                    }
                    Hairline()
                    settingRow(label: "Midsleep") {
                        Text(midsleepText)
                            .font(Typography.mono(13, weight: .medium))
                            .foregroundStyle(Color.amber)
                    }
                }
            }
        }
    }

    private var tripGroup: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionTag(text: "TRIP")
                .padding(.horizontal, Spacing.xs)

            InstrumentCard(padding: 0) {
                if state.trip != nil {
                    Button {
                        showingClearAlert = true
                    } label: {
                        HStack {
                            Text("Clear current trip")
                                .font(Typography.body(15, weight: .medium))
                                .foregroundStyle(Color.advisoryRed)
                            Spacer()
                            Text("→")
                                .font(Typography.mono(13, weight: .medium))
                                .foregroundStyle(Color.advisoryRed)
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack {
                        Text("No active trip")
                            .font(Typography.body(15, weight: .medium))
                            .foregroundStyle(Color.textLo)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                }
            }
        }
    }

    private var importantGroup: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionTag(text: "IMPORTANT")
                .padding(.horizontal, Spacing.xs)

            InstrumentCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("This app provides general guidance based on circadian-rhythm research. It is not medical advice.")
                        .font(Typography.body(13))
                        .foregroundStyle(Color.textMid)
                    Text("Melatonin availability and dosage rules vary by country. Consult a qualified healthcare professional before starting any supplementation.")
                        .font(Typography.body(13))
                        .foregroundStyle(Color.textLo)
                }
            }
        }
    }

    private var versionGroup: some View {
        InstrumentCard(padding: 0) {
            VStack(spacing: 0) {
                settingRow(label: "Version") {
                    Text("0.1 · MVP")
                        .font(Typography.mono(13, weight: .medium))
                        .foregroundStyle(Color.textLo)
                }
                Hairline()
                settingRow(label: "Data") {
                    Text("LOCAL · ON-DEVICE")
                        .font(Typography.mono(11, weight: .semibold))
                        .trackedUppercase(1.4)
                        .foregroundStyle(Color.amber)
                }
            }
        }
    }

    // MARK: Pieces

    @ViewBuilder
    private func settingRow<Trailing: View>(label: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack {
            Text(label)
                .font(Typography.body(15, weight: .medium))
                .foregroundStyle(Color.textHi)
            Spacer()
            trailing()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    private var midsleepText: String {
        let bed = state.sleepSchedule.bedtimeHour
        let wakeHour = state.sleepSchedule.wakeHour
        // Midpoint of sleep, wrapping past midnight.
        var span = wakeHour - bed
        if span < 0 { span += 24 }
        var mid = bed + span / 2
        if mid >= 24 { mid -= 24 }
        let h = Int(mid)
        let m = Int(((mid - Double(h)) * 60).rounded())
        return String(format: "%02d:%02d", h, m)
    }

    private func hydrate() {
        bedtime = Self.timeFromHour(state.sleepSchedule.bedtimeHour)
        wake    = Self.timeFromHour(state.sleepSchedule.wakeHour)
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
