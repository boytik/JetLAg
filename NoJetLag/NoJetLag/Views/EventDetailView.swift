import SwiftUI

/// Sheet that explains a single PlanEvent — its scientific rationale and the
/// peer-reviewed source. Opened by tapping an event row or the active card.
struct EventDetailView: View {
    let event: PlanEvent
    @Environment(\.dismiss) private var dismiss

    private var rationale: EventRationale { event.kind.rationale }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg0.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        header
                        summarySection
                        mechanismSection
                        researchSection
                        if event.kind == .takeMelatonin {
                            disclaimerSection
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("WHY")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CLOSE") { dismiss() }
                        .font(Typography.mono(11, weight: .semibold))
                        .foregroundStyle(Color.textLo)
                }
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                EventBadge(kind: event.kind)
                Text(timeRangeText)
                    .font(Typography.mono(11, weight: .medium))
                    .trackedUppercase(1.4)
                    .foregroundStyle(Color.textLo)
            }
            Text(event.kind.title)
                .font(Typography.display(28, weight: .semibold))
                .foregroundStyle(Color.textHi)
        }
    }

    private var summarySection: some View {
        InstrumentCard {
            HStack(alignment: .top, spacing: Spacing.md) {
                Rectangle()
                    .fill(Color.amber)
                    .frame(width: 2)
                Text(rationale.summary)
                    .font(Typography.body(15, weight: .medium))
                    .foregroundStyle(Color.textHi)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var mechanismSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionTag(text: "MECHANISM")
                .padding(.horizontal, Spacing.xs)

            InstrumentCard {
                Text(rationale.detail)
                    .font(Typography.body(14))
                    .foregroundStyle(Color.textMid)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var researchSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionTag(text: "RESEARCH")
                .padding(.horizontal, Spacing.xs)

            InstrumentCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(rationale.citation.short)
                        .font(Typography.mono(13, weight: .semibold))
                        .foregroundStyle(Color.amber)

                    Text(rationale.citation.title)
                        .font(Typography.body(14, weight: .medium))
                        .foregroundStyle(Color.textHi)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(rationale.citation.venue)
                        .font(Typography.mono(11))
                        .foregroundStyle(Color.textLo)

                    if let url = rationale.citation.url, let link = URL(string: url) {
                        Link(destination: link) {
                            HStack(spacing: 4) {
                                Text("OPEN SOURCE")
                                    .font(Typography.mono(10, weight: .semibold))
                                    .trackedUppercase(1.4)
                                Text("→")
                                    .font(Typography.mono(11, weight: .semibold))
                            }
                            .foregroundStyle(Color.amber)
                        }
                        .padding(.top, Spacing.xs)
                    }
                }
            }
        }
    }

    private var disclaimerSection: some View {
        let country = MelatoninLegality.current
        let status = country.status
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("LEGAL · \(country.regionCode.isEmpty ? "REGION" : country.regionCode)")
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(status.color)
                Spacer()
                Text(status.label)
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.4)
                    .foregroundStyle(status.color)
            }
            .padding(.horizontal, Spacing.xs)

            InstrumentCard {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(status.headline)
                        .font(Typography.body(14, weight: .semibold))
                        .foregroundStyle(status.color)
                    Text(status.advisory)
                        .font(Typography.body(13))
                        .foregroundStyle(Color.textMid)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Helpers

    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.timeZone = event.displayTimeZone
        formatter.dateFormat = "HH:mm"
        let start = formatter.string(from: event.startsAt)
        let abbr = event.displayTimeZone.abbreviation() ?? ""
        if let end = event.endsAt {
            return "\(start) — \(formatter.string(from: end)) \(abbr)"
        }
        return "\(start) \(abbr)"
    }
}
