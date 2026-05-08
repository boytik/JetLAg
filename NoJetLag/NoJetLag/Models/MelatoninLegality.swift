import SwiftUI

/// Regulatory status of melatonin in a given country. Source data was compiled
/// from public regulatory information as of 2026 — it is not legal advice and
/// can become outdated when local rules change. Always have the user verify
/// the current status before they purchase or carry melatonin across borders.
enum MelatoninStatus {
    /// Sold over the counter / as a dietary supplement without prescription.
    case overTheCounter
    /// Requires a clinician's prescription to purchase.
    case prescription
    /// Status varies by dose, formulation, or recent regulation changes.
    case varies

    /// Short uppercase label for badges and tags.
    var label: String {
        switch self {
        case .overTheCounter: return "OTC"
        case .prescription:   return "RX ONLY"
        case .varies:         return "CHECK LOCALLY"
        }
    }

    /// Long form headline for callouts.
    var headline: String {
        switch self {
        case .overTheCounter: return "Over the counter"
        case .prescription:   return "Prescription only"
        case .varies:         return "Status varies"
        }
    }

    /// Advisory paragraph shown to the user.
    var advisory: String {
        switch self {
        case .overTheCounter:
            return "Melatonin is sold as a dietary supplement in your region. Still consult a clinician about dose and timing — the optimal phase-shifting dose (0.3-0.5 mg) is much smaller than the 3-5 mg tablets commonly on shelves."
        case .prescription:
            return "Melatonin is classified as a prescription medication in your region. Do not import it for personal use without checking customs rules. If you intend to follow this protocol, ask a clinician for a prescription."
        case .varies:
            return "Melatonin status varies by dose, formulation, or recent regulation changes in your region. Verify current local rules before purchasing or carrying melatonin across borders."
        }
    }

    /// Color used for badges, headlines, callouts.
    var color: Color {
        switch self {
        case .overTheCounter: return Color.caffeineGreen
        case .prescription:   return Color.advisoryRed
        case .varies:         return Color.amber
        }
    }
}

/// Compiled regulatory snapshot. Best-effort, public-source data — labelled
/// as "as of 2026" so users know it can drift.
enum MelatoninLegality {
    struct Country {
        let regionCode: String   // ISO 3166-1 alpha-2
        let name: String
        let status: MelatoninStatus
        let note: String?        // optional caveat (e.g., dose-specific rule)
    }

    static let countries: [Country] = [
        // Over the counter
        Country(regionCode: "US", name: "United States",  status: .overTheCounter, note: nil),
        Country(regionCode: "CA", name: "Canada",         status: .overTheCounter, note: nil),
        Country(regionCode: "MX", name: "Mexico",         status: .overTheCounter, note: nil),
        Country(regionCode: "BR", name: "Brazil",         status: .overTheCounter, note: "OTC since 2021"),
        Country(regionCode: "AR", name: "Argentina",      status: .overTheCounter, note: nil),
        Country(regionCode: "CN", name: "China",          status: .overTheCounter, note: "Sold as a supplement"),
        Country(regionCode: "HK", name: "Hong Kong",      status: .overTheCounter, note: nil),
        Country(regionCode: "TH", name: "Thailand",       status: .overTheCounter, note: nil),
        Country(regionCode: "VN", name: "Vietnam",        status: .overTheCounter, note: nil),
        Country(regionCode: "PH", name: "Philippines",    status: .overTheCounter, note: nil),
        Country(regionCode: "ID", name: "Indonesia",      status: .overTheCounter, note: nil),
        Country(regionCode: "IN", name: "India",          status: .overTheCounter, note: nil),

        // Prescription
        Country(regionCode: "RU", name: "Russia",         status: .prescription,   note: nil),
        Country(regionCode: "FR", name: "France",         status: .prescription,   note: "OTC up to 1 mg"),
        Country(regionCode: "DE", name: "Germany",        status: .prescription,   note: nil),
        Country(regionCode: "ES", name: "Spain",          status: .prescription,   note: "OTC up to 1.99 mg"),
        Country(regionCode: "IT", name: "Italy",          status: .prescription,   note: "OTC up to 1 mg"),
        Country(regionCode: "NL", name: "Netherlands",    status: .prescription,   note: "OTC up to 0.3 mg"),
        Country(regionCode: "BE", name: "Belgium",        status: .prescription,   note: nil),
        Country(regionCode: "SE", name: "Sweden",         status: .prescription,   note: nil),
        Country(regionCode: "NO", name: "Norway",         status: .prescription,   note: nil),
        Country(regionCode: "FI", name: "Finland",        status: .prescription,   note: nil),
        Country(regionCode: "DK", name: "Denmark",        status: .prescription,   note: nil),
        Country(regionCode: "PL", name: "Poland",         status: .prescription,   note: nil),
        Country(regionCode: "CZ", name: "Czech Republic", status: .prescription,   note: nil),
        Country(regionCode: "AT", name: "Austria",        status: .prescription,   note: nil),
        Country(regionCode: "CH", name: "Switzerland",    status: .prescription,   note: nil),
        Country(regionCode: "IE", name: "Ireland",        status: .prescription,   note: nil),
        Country(regionCode: "AU", name: "Australia",      status: .prescription,   note: "OTC 2 mg slow-release for 55+"),
        Country(regionCode: "NZ", name: "New Zealand",    status: .prescription,   note: nil),
        Country(regionCode: "JP", name: "Japan",          status: .prescription,   note: "Ramelteon is the prescription drug"),
        Country(regionCode: "KR", name: "South Korea",    status: .prescription,   note: nil),

        // Varies / dose-dependent
        Country(regionCode: "GB", name: "United Kingdom", status: .varies,         note: "OTC up to 0.3 mg, RX above"),
        Country(regionCode: "AE", name: "United Arab Emirates", status: .varies,   note: "Restricted; verify before carrying"),
        Country(regionCode: "SG", name: "Singapore",      status: .varies,         note: "Dose- and formulation-dependent"),
        Country(regionCode: "TR", name: "Turkey",         status: .varies,         note: nil),
        Country(regionCode: "IL", name: "Israel",         status: .varies,         note: "OTC for 55+, RX for younger"),
    ]

    /// Lookup status by ISO 3166 region code. Falls back to `.varies` for
    /// any unknown region (safer than guessing OTC).
    static func status(forRegionCode code: String?) -> Country {
        let normalized = (code ?? "").uppercased()
        if let match = countries.first(where: { $0.regionCode == normalized }) {
            return match
        }
        return Country(
            regionCode: normalized,
            name: regionDisplayName(normalized),
            status: .varies,
            note: nil
        )
    }

    /// Best-effort human-readable name for an unknown region code.
    private static func regionDisplayName(_ code: String) -> String {
        let locale = Locale.current
        if let name = locale.localizedString(forRegionCode: code), !name.isEmpty {
            return name
        }
        return code.isEmpty ? "Your region" : code
    }

    /// Snapshot for the user's current iPhone region.
    static var current: Country {
        let code: String?
        if #available(iOS 16, *) {
            code = Locale.current.region?.identifier
        } else {
            code = Locale.current.regionCode
        }
        return status(forRegionCode: code)
    }
}
