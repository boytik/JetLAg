import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.openURL) private var openURL
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
                        ambienceGroup
                        tripGroup
                        melatoninGroup
                        feedbackGroup
                        importantGroup
                        versionGroup
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xl)
                }
            }
            .navigationTitle("SETTINGS")
            .navigationBarTitleDisplayMode(.inline)
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

    // MARK: Ambience

    private var ambienceGroup: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionTag(text: "AMBIENCE")
                .padding(.horizontal, Spacing.xs)

            InstrumentCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(BackgroundSound.allCases) { sound in
                        soundRow(sound)
                        if sound != BackgroundSound.allCases.last {
                            Hairline()
                        }
                    }
                    Hairline()
                    captionRow
                    Hairline()
                    volumeRow
                }
            }
        }
    }

    private func soundRow(_ sound: BackgroundSound) -> some View {
        let selected = (state.backgroundSound == sound)
        return Button {
            state.backgroundSound = sound
        } label: {
            HStack(spacing: Spacing.md) {
                Text(sound.label)
                    .font(Typography.mono(13, weight: .semibold))
                    .trackedUppercase(1.4)
                    .foregroundStyle(selected ? Color.amber : Color.textHi)
                Spacer()
                selectionIndicator(selected: selected)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func selectionIndicator(selected: Bool) -> some View {
        if selected {
            Circle()
                .fill(Color.amber)
                .frame(width: 8, height: 8)
        } else {
            Circle()
                .stroke(Color.stroke, lineWidth: 1)
                .frame(width: 8, height: 8)
        }
    }

    private var captionRow: some View {
        HStack {
            Text(state.backgroundSound.caption)
                .font(Typography.body(12))
                .foregroundStyle(Color.textLo)
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }

    private var volumeRow: some View {
        let off = (state.backgroundSound == .off)
        return HStack(spacing: Spacing.md) {
            Text("VOL")
                .font(Typography.mono(11, weight: .semibold))
                .trackedUppercase(1.4)
                .foregroundStyle(Color.textLo)
                .frame(width: 32, alignment: .leading)

            Slider(value: Binding(
                get: { state.backgroundVolume },
                set: { state.backgroundVolume = $0 }
            ), in: 0...1)
            .tint(Color.amber)
            .disabled(off)

            Text(String(format: "%d%%", Int((state.backgroundVolume * 100).rounded())))
                .font(Typography.mono(11, weight: .medium))
                .foregroundStyle(Color.textMid)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .opacity(off ? 0.4 : 1)
    }

    // MARK: Trip

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

    private var melatoninGroup: some View {
        let country = MelatoninLegality.current
        let status = country.status
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionTag(text: "MELATONIN")
                .padding(.horizontal, Spacing.xs)

            InstrumentCard(padding: 0) {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(country.regionCode.isEmpty ? "Your region" : country.name)
                                .font(Typography.body(15, weight: .medium))
                                .foregroundStyle(Color.textHi)
                            Text(status.headline)
                                .font(Typography.mono(11, weight: .medium))
                                .foregroundStyle(status.color)
                        }
                        Spacer()
                        Text(status.label)
                            .font(Typography.mono(9, weight: .semibold))
                            .trackedUppercase(1.4)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .foregroundStyle(status.color)
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.sm)
                                    .stroke(status.color, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)

                    Hairline()

                    NavigationLink {
                        MelatoninLegalityView()
                    } label: {
                        HStack {
                            Text("Full breakdown by country")
                                .font(Typography.body(15, weight: .medium))
                                .foregroundStyle(Color.textHi)
                            Spacer()
                            Text("→")
                                .font(Typography.mono(13, weight: .medium))
                                .foregroundStyle(Color.amber)
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var feedbackGroup: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionTag(
                text: "FEEDBACK",
                trailing: state.feedbackHistory.isEmpty ? nil : "\(state.feedbackHistory.count) ON FILE"
            )
            .padding(.horizontal, Spacing.xs)

            InstrumentCard(padding: 0) {
                VStack(spacing: 0) {
                    NavigationLink {
                        HistoryView()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Trip history")
                                    .font(Typography.body(15, weight: .medium))
                                    .foregroundStyle(Color.textHi)
                                Text(historySubtitle)
                                    .font(Typography.mono(11))
                                    .foregroundStyle(Color.textLo)
                            }
                            Spacer()
                            Text("→")
                                .font(Typography.mono(13, weight: .medium))
                                .foregroundStyle(Color.amber)
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                    }
                    .buttonStyle(.plain)

                    Hairline()

                    Button {
                        if let url = generalFeedbackURL {
                            openURL(url)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Send general feedback")
                                    .font(Typography.body(15, weight: .medium))
                                    .foregroundStyle(Color.textHi)
                                Text(NoJetLagContact.feedbackEmail)
                                    .font(Typography.mono(11))
                                    .foregroundStyle(Color.textLo)
                            }
                            Spacer()
                            Text("→")
                                .font(Typography.mono(13, weight: .medium))
                                .foregroundStyle(Color.amber)
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var historySubtitle: String {
        if state.feedbackHistory.isEmpty {
            return "No entries yet"
        }
        return "\(state.feedbackHistory.count) trip\(state.feedbackHistory.count == 1 ? "" : "s") rated"
    }

    private var generalFeedbackURL: URL? {
        let subject = "NoJetLag — general feedback"
        let body = """
        App version: \(NoJetLagContact.appVersion) (\(NoJetLagContact.appBuild))

        """
        let allowed = CharacterSet.urlQueryAllowed
        guard
            let s = subject.addingPercentEncoding(withAllowedCharacters: allowed),
            let b = body.addingPercentEncoding(withAllowedCharacters: allowed)
        else { return nil }
        return URL(string: "mailto:\(NoJetLagContact.feedbackEmail)?subject=\(s)&body=\(b)")
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
