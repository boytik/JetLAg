import SwiftUI

/// Three-question feedback form. Saves locally to AppState and optionally
/// opens the user's mail client with a pre-filled email to feedback@.
struct FeedbackEntryView: View {
    let trip: Trip
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var state: AppState

    @State private var sleepDay1: Int = 3
    @State private var manageability: Int = 3
    @State private var overall: Int = 3
    @State private var comments: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg0.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        header
                        ratingCard(
                            tag: "Q1",
                            title: "Day-1 sleep quality",
                            subtitle: "How well did you sleep on the first night at the destination?",
                            value: $sleepDay1
                        )
                        ratingCard(
                            tag: "Q2",
                            title: "Protocol manageability",
                            subtitle: "How realistic was it to follow the schedule in real life?",
                            value: $manageability
                        )
                        ratingCard(
                            tag: "Q3",
                            title: "Overall recommendation",
                            subtitle: "Would you use this approach again on the next trip?",
                            value: $overall
                        )
                        commentsCard
                        actions
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("FEEDBACK")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CANCEL") { dismiss() }
                        .font(Typography.mono(11, weight: .semibold))
                        .foregroundStyle(Color.textLo)
                }
            }
        }
    }

    // MARK: Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("RATE THIS TRIP")
                .font(Typography.mono(10, weight: .semibold))
                .trackedUppercase(1.6)
                .foregroundStyle(Color.amber)
            Text(routeText)
                .font(Typography.display(28, weight: .semibold))
                .foregroundStyle(Color.textHi)
            Text("\(shiftText) · \(arrivalText)")
                .font(Typography.mono(11, weight: .medium))
                .foregroundStyle(Color.textLo)
        }
    }

    private func ratingCard(tag: String, title: String, subtitle: String, value: Binding<Int>) -> some View {
        InstrumentCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text(tag)
                        .font(Typography.mono(10, weight: .semibold))
                        .trackedUppercase(1.6)
                        .foregroundStyle(Color.amber)
                    Spacer()
                    Text("\(value.wrappedValue) / 5")
                        .font(Typography.mono(11, weight: .semibold))
                        .foregroundStyle(Color.textLo)
                }
                Text(title)
                    .font(Typography.body(15, weight: .semibold))
                    .foregroundStyle(Color.textHi)
                Text(subtitle)
                    .font(Typography.body(12))
                    .foregroundStyle(Color.textLo)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: Spacing.sm) {
                    ForEach(1...5, id: \.self) { i in
                        Button {
                            value.wrappedValue = i
                        } label: {
                            Circle()
                                .fill(i <= value.wrappedValue ? Color.amber : Color.bg2)
                                .overlay(
                                    Circle().stroke(
                                        i <= value.wrappedValue ? Color.amber : Color.stroke,
                                        lineWidth: 1
                                    )
                                )
                                .frame(width: 26, height: 26)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.top, Spacing.xs)
            }
        }
    }

    private var commentsCard: some View {
        InstrumentCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("COMMENTS")
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.textLo)
                Text("Anything specific that worked or didn't? Optional.")
                    .font(Typography.body(12))
                    .foregroundStyle(Color.textLo)

                ZStack(alignment: .topLeading) {
                    if comments.isEmpty {
                        Text("Day 2 melatonin felt too late. Light timing was great.")
                            .font(Typography.body(13))
                            .foregroundStyle(Color.textLo.opacity(0.6))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    TextEditor(text: $comments)
                        .font(Typography.body(13))
                        .foregroundStyle(Color.textHi)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100)
                }
                .padding(8)
                .background(Color.bg2)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .stroke(Color.stroke, lineWidth: 1)
                )
            }
        }
    }

    private var actions: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                saveAndShare()
            } label: {
                Text("SAVE & SEND VIA EMAIL")
                    .trackedUppercase(1.4)
            }
            .buttonStyle(.instrument)

            Button {
                saveOnly()
            } label: {
                Text("SAVE ONLY")
                    .trackedUppercase(1.4)
            }
            .buttonStyle(.instrumentSecondary)

            Text("Stored on-device. Email sends a plain-text summary to \(NoJetLagContact.feedbackEmail).")
                .font(Typography.body(11))
                .foregroundStyle(Color.textLo)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.xs)
        }
        .padding(.top, Spacing.sm)
    }

    // MARK: Actions

    private func saveAndShare() {
        let fb = persist()
        if let url = mailtoURL(for: fb) {
            openURL(url)
        }
        dismiss()
    }

    private func saveOnly() {
        _ = persist()
        dismiss()
    }

    @discardableResult
    private func persist() -> TripFeedback {
        let fb = TripFeedback(
            trip: trip,
            sleepDay1: sleepDay1,
            manageability: manageability,
            overall: overall,
            comments: comments.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        state.feedbackHistory.append(fb)
        return fb
    }

    private func mailtoURL(for fb: TripFeedback) -> URL? {
        let subject = "NoJetLag feedback — \(fb.routeShortText)"
        let body = composeEmailBody(fb: fb)
        let allowed = CharacterSet.urlQueryAllowed
        guard
            let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: allowed),
            let encodedBody = body.addingPercentEncoding(withAllowedCharacters: allowed)
        else {
            return nil
        }
        let urlString = "mailto:\(NoJetLagContact.feedbackEmail)?subject=\(encodedSubject)&body=\(encodedBody)"
        return URL(string: urlString)
    }

    private func composeEmailBody(fb: TripFeedback) -> String {
        let dotsSleep = bar(fb.sleepDay1)
        let dotsManage = bar(fb.manageability)
        let dotsOverall = bar(fb.overall)
        let arrivalString = ISO8601DateFormatter().string(from: fb.arrivalDate)
        let comments = fb.comments.isEmpty ? "(none)" : fb.comments

        return """
        NoJetLag feedback
        =================

        Trip:         \(fb.routeLongText)
        Route:        \(fb.routeShortText)
        Shift:        \(fb.shiftText)
        Arrival:      \(arrivalString)
        App version:  \(NoJetLagContact.appVersion) (\(NoJetLagContact.appBuild))

        Day-1 sleep quality:        \(dotsSleep) (\(fb.sleepDay1)/5)
        Protocol manageability:     \(dotsManage) (\(fb.manageability)/5)
        Overall recommendation:     \(dotsOverall) (\(fb.overall)/5)

        Comments:
        \(comments)

        — Sent from NoJetLag
        """
    }

    private func bar(_ score: Int) -> String {
        let filled = String(repeating: "●", count: max(0, min(5, score)))
        let empty = String(repeating: "○", count: max(0, 5 - score))
        return filled + empty
    }

    // MARK: Display strings

    private var routeText: String {
        "\(TripFeedback.airportCode(trip.originTimeZoneId)) → \(TripFeedback.airportCode(trip.destinationTimeZoneId))"
    }

    private var shiftText: String {
        let s = trip.timeZoneShiftHours
        if abs(s) < 1 { return "SAME TZ" }
        let sign = s > 0 ? "+" : "-"
        let h = String(format: "%.1f", abs(s))
        let dir = s > 0 ? "ADVANCE" : "DELAY"
        return "\(sign)\(h)H · \(dir)"
    }

    private var arrivalText: String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        f.timeZone = trip.destinationTimeZone
        return f.string(from: trip.arrival).uppercased()
    }
}
