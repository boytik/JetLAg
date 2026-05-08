import SwiftUI

/// Full breakdown of melatonin regulatory status by country, grouped by status.
/// Pushed onto the Settings stack from the MELATONIN section.
struct MelatoninLegalityView: View {
    @Environment(\.dismiss) private var dismiss

    private var grouped: [(status: MelatoninStatus, countries: [MelatoninLegality.Country])] {
        let order: [MelatoninStatus] = [.prescription, .varies, .overTheCounter]
        return order.map { s in
            (status: s, countries: MelatoninLegality.countries.filter { $0.status == s }
                                                              .sorted { $0.name < $1.name })
        }
    }

    var body: some View {
        ZStack {
            Color.bg0.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    intro
                    ForEach(grouped, id: \.status.label) { group in
                        section(status: group.status, countries: group.countries)
                    }
                    disclaimer
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .navigationTitle("MELATONIN")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Sections

    private var intro: some View {
        InstrumentCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Why this matters")
                    .font(Typography.body(15, weight: .semibold))
                    .foregroundStyle(Color.textHi)
                Text("Melatonin's regulatory status varies sharply by country. In some places it's a dietary supplement on every drug-store shelf; in others it's a prescription-only medication and bringing your own through customs can be a problem.")
                    .font(Typography.body(13))
                    .foregroundStyle(Color.textMid)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func section(status: MelatoninStatus, countries: [MelatoninLegality.Country]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(status.headline.uppercased())
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(status.color)
                Spacer()
                Text("\(countries.count)")
                    .font(Typography.mono(10, weight: .semibold))
                    .foregroundStyle(Color.textLo)
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.bottom, Spacing.xs)
            .overlay(alignment: .bottom) { Hairline() }

            InstrumentCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(countries.enumerated()), id: \.element.regionCode) { idx, country in
                        countryRow(country)
                        if idx < countries.count - 1 {
                            Hairline()
                        }
                    }
                }
            }
        }
    }

    private func countryRow(_ country: MelatoninLegality.Country) -> some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Text(country.regionCode)
                .font(Typography.mono(11, weight: .semibold))
                .trackedUppercase(1.4)
                .foregroundStyle(country.status.color)
                .frame(width: 32, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(country.name)
                    .font(Typography.body(14, weight: .medium))
                    .foregroundStyle(Color.textHi)
                if let note = country.note {
                    Text(note)
                        .font(Typography.body(11))
                        .foregroundStyle(Color.textLo)
                        .lineLimit(2)
                }
            }
            Spacer()
            Text(country.status.label)
                .font(Typography.mono(9, weight: .semibold))
                .trackedUppercase(1.4)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .foregroundStyle(country.status.color)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .stroke(country.status.color, lineWidth: 1)
                )
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    private var disclaimer: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("DATA SOURCE")
                .font(Typography.mono(10, weight: .semibold))
                .trackedUppercase(1.6)
                .foregroundStyle(Color.textLo)
            Text("Compiled from public regulatory information as of 2026. Not legal advice. Rules change — verify locally before purchasing or carrying melatonin across borders.")
                .font(Typography.body(11))
                .foregroundStyle(Color.textLo)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.xs)
    }
}
