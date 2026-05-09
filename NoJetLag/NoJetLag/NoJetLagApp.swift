import SwiftUI
import UIKit
import Adapty
import AdaptyUI

@main
struct NoJetLagApp: App {
    @UIApplicationDelegateAdaptor(NoJetLagAppDelegate.self) private var appDelegate
    @StateObject private var state = AppState.load()

    /// Public live SDK key for Adapty. Safe to embed in client code.
    static let adaptyPublicKey = "public_live_MTeM1tRN.XtRSQnI7XEkKAW4lGHgT"

    /// Adapty placement ID for the onboarding configured in the dashboard.
    static let adaptyOnboardingPlacementId = "Important"

    /// Single shared activation Task — runs `Adapty.activate(with:)` and
    /// then `AdaptyUI.activate()` exactly once. Anyone who needs the SDK
    /// ready awaits `.value` on this Task. Initialised lazily on first
    /// access; we touch it from `init()` to start activation immediately.
    static let adaptyActivation: Task<Void, Error> = {
        // Capture the MainActor-isolated key here, in the outer closure
        // which runs at static-init time on MainActor. This avoids the
        // "Expression is 'async' but is not marked with 'await'" warning
        // we'd hit if we read `adaptyPublicKey` directly inside the
        // non-isolated `Task { }` body.
        let key = adaptyPublicKey
        return Task {
            let configuration = AdaptyConfiguration
                .builder(withAPIKey: key)
                .build()
            try await Adapty.activate(with: configuration)
            // AdaptyUI requires its own activation step in addition to
            // Adapty.activate — without this the onboarding view config
            // request fails with `AdaptyUIErrorDomain 4002`. In recent
            // SDK versions this call is async.
            try await AdaptyUI.activate()
        }
    }()

    init() {
        Self.configureAppearance()
        // Kick off the lazy activation Task right away.
        _ = Self.adaptyActivation
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
