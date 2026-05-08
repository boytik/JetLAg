import SwiftUI
import UIKit

@main
struct NoJetLagApp: App {
    @StateObject private var state = AppState.load()

    init() {
        Self.configureAppearance()
        Self.activateAdaptyIfPossible()
    }

    /// One-shot Adapty SDK activation. Call this BEFORE any view tries to
    /// fetch onboarding/paywall content.
    ///
    /// **TODO(adapty):** once AdaptySDK is imported in this target:
    ///   1. Add `import Adapty` and `import AdaptyUI` at the top of this file.
    ///   2. Replace the body below with:
    ///         Adapty.activate("YOUR_PUBLIC_SDK_KEY")
    ///         AdaptyUI.activate()
    ///   3. (Optional) set `AdaptyUI.delegate = …` if you need analytics hooks.
    private static func activateAdaptyIfPossible() {
        // Placeholder — no-op. The AdaptyOnboardingHost shows a stub until
        // this is wired.
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
                .preferredColorScheme(.dark) // dark primary; flip to nil to follow system
                .tint(Color.amber)
        }
    }

    /// One-shot UIKit appearance configuration. SwiftUI inherits these styles
    /// for nav bars and tab bars wrapped in NavigationStack / TabView.
    private static func configureAppearance() {
        // Nav bar — solid bg0, no translucent material, condensed bold title
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(Color.bg0)
        nav.shadowColor = UIColor(Color.stroke)

        let titleFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
        let largeFont = UIFont.systemFont(ofSize: 26, weight: .semibold)
        nav.titleTextAttributes = [
            .foregroundColor: UIColor(Color.textHi),
            .font: titleFont
        ]
        nav.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.textHi),
            .font: largeFont
        ]

        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(Color.amber)

        // Tab bar — solid bg0, amber selected, mono labels
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(Color.bg0)
        tab.shadowColor = UIColor(Color.stroke)

        let tabFont = UIFont.monospacedSystemFont(ofSize: 10, weight: .semibold)
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.textLo),
            .font: tabFont,
            .kern: 1.4
        ]
        let selectedAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.amber),
            .font: tabFont,
            .kern: 1.4
        ]
        for itemAppearance in [tab.stackedLayoutAppearance, tab.inlineLayoutAppearance, tab.compactInlineLayoutAppearance] {
            itemAppearance.normal.titleTextAttributes = normalAttrs
            itemAppearance.selected.titleTextAttributes = selectedAttrs
            itemAppearance.normal.iconColor = UIColor(Color.textLo)
            itemAppearance.selected.iconColor = UIColor(Color.amber)
        }

        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = UIColor(Color.amber)
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.textLo)
    }
}
