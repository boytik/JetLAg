import Foundation
import Combine

// =============================================================================
//  WebRecoveryStore — privacy-URL caching with three-state semantics
//  -----------------------------------------------------------------------------
//  `savedURL: String?` carries three meanings:
//
//    • `""`     → INITIAL: user has never tapped Privacy.
//                Onboarding gate is active.
//
//    • "<url>"  → LOADED: a previous tap successfully reached the page.
//                Stored value is the final URL after redirects.
//                Onboarding gate is active until the user taps Adapty's
//                Close button — but the next privacy tap reuses this URL
//                instead of going back through Adapty's remote config.
//
//    • `nil`    → FAILED: the last load attempt failed (after retry-once).
//                Onboarding gate is considered PASSED — we don't punish
//                the user when the client's privacy site is broken.
//
//  `pathID` is the value of the `?pathid=XYZ` query parameter on the
//  saved URL — kept across failures so `<base>?pathid=XYZ` can be tried
//  as a synthetic recovery even after `savedURL` has been wiped to nil.
//  Matches the Foltey/Stellara convention.
//
//  Persistence: a separate `*.everSet` boolean distinguishes "first
//  launch, key absent" (→ `""`) from "key explicitly set to nil"
//  (→ FAILED state).
// =============================================================================

@MainActor
final class WebRecoveryStore: ObservableObject {
    static let shared = WebRecoveryStore()

    private static let savedURLKey  = "nojetlag.web.recovery.savedURL.v2"
    private static let pathIDKey    = "nojetlag.web.recovery.pathID.v2"
    private static let everSetKey   = "nojetlag.web.recovery.everSet.v2"

    /// Name of the query parameter that carries the recovery hint. Foltey
    /// uses lowercase `pathid`; we match it for compatibility.
    private static let pathIDQueryName = "pathid"

    /// See class header for the three meanings.
    @Published private(set) var savedURL: String? = ""
    /// Value of the saved URL's `?pathid=XYZ` query parameter, preserved
    /// across failures so `<base>?pathid=XYZ` can serve as a synthetic
    /// fallback when the cached URL no longer resolves.
    @Published private(set) var pathID: String?

    private init() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: Self.everSetKey) {
            // A previous session wrote a value (could be a string, "", or
            // nil-after-failure). UserDefaults can't distinguish "absent"
            // from "nil-set", which is why we need the `everSet` flag.
            savedURL = defaults.string(forKey: Self.savedURLKey)
        } else {
            savedURL = ""
        }
        pathID = defaults.string(forKey: Self.pathIDKey)
    }

    // MARK: - Public API

    /// Convenience: parsed URL of the saved string, or nil if empty/nil.
    var savedURLValue: URL? {
        guard let s = savedURL, !s.isEmpty else { return nil }
        return URL(string: s)
    }

    /// Save the final URL after a successful main-frame load.
    /// Sets `savedURL` to the URL string and refreshes `pathID` (only when
    /// the URL actually carries a `?pathid=…` query — otherwise the
    /// previously stored pathID is preserved).
    func captureFinal(_ url: URL) {
        savedURL = url.absoluteString
        if let extracted = Self.extractPathID(from: url) {
            pathID = extracted
        }
        persist()
    }

    /// Mark the load as failed after retry-once. `savedURL = nil`,
    /// `pathID` is preserved for synthetic recovery on later attempts.
    /// This flips the onboarding gate to PASSED.
    func markFailed() {
        savedURL = nil
        // Keep pathID — it's the whole point of synthetic-recovery design.
        persist()
    }

    /// Full reset back to the initial state. Used by the DEBUG QA reset.
    func clear() {
        savedURL = ""
        pathID = nil
        UserDefaults.standard.removeObject(forKey: Self.everSetKey)
        UserDefaults.standard.removeObject(forKey: Self.savedURLKey)
        UserDefaults.standard.removeObject(forKey: Self.pathIDKey)
    }

    /// Best URL to load for a given base — preferring `savedURL`, then
    /// `<base>?pathid=XYZ`, finally the bare base.
    func fallbackURL(forBase base: URL) -> URL {
        if let url = savedURLValue { return url }
        if let synth = syntheticURL(forBase: base) { return synth }
        return base
    }

    /// `<base>?pathid=<pathID>` if a `pathID` is on file; nil otherwise.
    /// Exposed so the retry flow can pick the synthetic URL without
    /// wiping `savedURL` first.
    func syntheticURL(forBase base: URL) -> URL? {
        guard let pathID, !pathID.isEmpty else { return nil }
        return Self.composeSynthetic(base: base, pathID: pathID)
    }

    // MARK: - Helpers

    /// Read the value of the `?pathid=…` query parameter (case-insensitive).
    /// Returns nil when the URL has no such parameter.
    private static func extractPathID(from url: URL) -> String? {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = comps.queryItems else { return nil }
        for item in items
        where item.name.caseInsensitiveCompare(Self.pathIDQueryName) == .orderedSame {
            if let value = item.value?.trimmingCharacters(in: .whitespaces),
               !value.isEmpty {
                return value
            }
        }
        return nil
    }

    /// Build `<base>?pathid=<pathID>`. Replaces any existing `pathid` query
    /// item on the base URL so we don't end up with duplicates.
    private static func composeSynthetic(base: URL, pathID: String) -> URL? {
        guard var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
            return nil
        }
        var items = components.queryItems ?? []
        items.removeAll { $0.name.caseInsensitiveCompare(Self.pathIDQueryName) == .orderedSame }
        items.append(URLQueryItem(name: Self.pathIDQueryName, value: pathID))
        components.queryItems = items
        return components.url
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: Self.everSetKey)
        if let savedURL {
            defaults.set(savedURL, forKey: Self.savedURLKey)
        } else {
            defaults.removeObject(forKey: Self.savedURLKey)
        }
        defaults.set(pathID, forKey: Self.pathIDKey)
    }
}
