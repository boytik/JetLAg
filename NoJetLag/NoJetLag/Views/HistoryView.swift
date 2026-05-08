import SwiftUI

/// Read-only list of every feedback entry the user has saved. Tap an entry
/// to expand its full details inline.
struct HistoryView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.openURL) private var openURL
    @State private var expandedId: UUID?

    private var entries: [TripFeedback] {
        state.feedbackHistory.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ZStack {
            Color.bg0.ignoresSafeArea()
            if entries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionTag(text: "RECORDED · \(entries.count)")
                            .padding(.horizontal, Spacing.xs)
                            .padding(.top, Spacing.sm)

                        ForEach(entries) { entry in
                            entryCard(entry)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xl)
                }
            }
        }
        .navigationTitle("HISTORY")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Pieces

    private func entryCard(_ entry: TripFeedback) -> some View {
        let expanded = (expandedId == entry.id)
        return InstrumentCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        expandedId = expanded ? nil : entry.id
                    }
                } label: {
                    headerRow(entry, expanded: expanded)
                }
                .buttonStyle(.plain)

                if expanded {
                    Hairline()
                    detailBlock(entry)
                }
            }
        }
    }

    private func headerRow(_ entry: TripFeedback, expanded: Bool) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.routeShortText)
                    .font(Typography.mono(15, weight: .semibold))
                    .foregroundStyle(Color.textHi)
                Text("\(entry.shiftText) · \(dateString(entry.arrivalDate))")
                    .font(Typography.mono(11))
                    .foregroundStyle(Color.textLo)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(barText(Int(entry.averageRating.rounded())))
                    .font(Typography.mono(13, weight: .medium))
                    .foregroundStyle(Color.amber)
                Text(String(format: "%.1f / 5", entry.averageRating))
                    .font(Typography.mono(10))
                    .foregroundStyle(Color.textLo)
            }
            Text(expanded ? "▾" : "▸")
                .font(Typography.mono(11, weight: .semibold))
                .foregroundStyle(Color.textLo)
        }
    }

    private func detailBlock(_ entry: TripFeedback) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ratingRow("Day-1 sleep", value: entry.sleepDay1)
            ratingRow("Manageability", value: entry.manageability)
            ratingRow("Overall", value: entry.overall)

            if !entry.comments.isEmpty {
                Text("COMMENTS")
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.textLo)
                    .padding(.top, Spacing.xs)
                Text(entry.comments)
                    .font(Typography.body(13))
                    .foregroundStyle(Color.textMid)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Text("RECORDED \(recordedDate(entry.createdAt))")
                    .font(Typography.mono(10))
                    .foregroundStyle(Color.textLo)
                Spacer()
                Button {
                    if let url = mailtoURL(for: entry) {
                        openURL(url)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("RE-SEND VIA EMAIL")
                            .font(Typography.mono(10, weight: .semibold))
                            .trackedUppercase(1.4)
                        Text("→")
                            .font(Typography.mono(11, weight: .semibold))
                    }
                    .foregroundStyle(Color.amber)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, Spacing.xs)
        }
    }

    private func ratingRow(_ label: String, value: Int) -> some View {
        HStack {
            Text(label)
                .font(Typography.body(13))
                .foregroundStyle(Color.textMid)
            Spacer()
            Text(barText(value))
                .font(Typography.mono(13, weight: .medium))
                .foregroundStyle(Color.amber)
            Text("\(value)/5")
                .font(Typography.mono(11))
                .foregroundStyle(Color.textLo)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            VStack(spacing: Spacing.sm) {
                Text("NO FEEDBACK YET")
                    .font(Typography.mono(11, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.textLo)
                Text("After your next trip, record a quick rating. Past entries land here.")
                    .font(Typography.body(15))
                    .foregroundStyle(Color.textMid)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Helpers

    private func barText(_ value: Int) -> String {
        let filled = String(repeating: "●", count: max(0, min(5, value)))
        let empty = String(repeating: "○", count: max(0, 5 - value))
        return filled + empty
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f.string(from: date).uppercased()
    }

    private func recordedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM · HH:mm"
        return f.string(from: date).uppercased()
    }

    private func mailtoURL(for fb: TripFeedback) -> URL? {
        let subject = "NoJetLag feedback — \(fb.routeShortText)"
        let body = composeEmailBody(fb: fb)
        let allowed = CharacterSet.urlQueryAllowed
        guard
            let encSub = subject.addingPercentEncoding(withAllowedCharacters: allowed),
            let encBody = body.addingPercentEncoding(withAllowedCharacters: allowed)
        else { return nil }
        return URL(string: "mailto:\(NoJetLagContact.feedbackEmail)?subject=\(encSub)&body=\(encBody)")
    }

    private func composeEmailBody(fb: TripFeedback) -> String {
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

        Day-1 sleep quality:        \(barText(fb.sleepDay1)) (\(fb.sleepDay1)/5)
        Protocol manageability:     \(barText(fb.manageability)) (\(fb.manageability)/5)
        Overall recommendation:     \(barText(fb.overall)) (\(fb.overall)/5)

        Comments:
        \(comments)

        — Sent from NoJetLag
        """
    }
}
