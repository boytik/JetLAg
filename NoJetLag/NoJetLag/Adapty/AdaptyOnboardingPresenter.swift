import SwiftUI
import Adapty
import AdaptyUI

// =============================================================================
//  Adapty onboarding presenter (SwiftUI-native)
//  -----------------------------------------------------------------------------
//  Uses Adapty 3.8+'s `AdaptyOnboardingView` directly — no UIKit wrapping.
//  Flow:
//    1. async-fetch the onboarding from the placement
//    2. sync-resolve its OnboardingConfiguration
//    3. hand the configuration to `AdaptyOnboardingView`
//    4. on close-action → `onComplete()` (flips the gate flag)
//    5. on error at any stage → error card with TRY AGAIN
// =============================================================================

/// SwiftUI host that loads + presents the Adapty onboarding for a placement.
/// Calls `onComplete` when the user closes the final onboarding screen.
struct AdaptyOnboardingPresenter: View {
    let placementId: String
    let onComplete: () -> Void

    @State private var phase: Phase = .preparing
    /// URLs harvested from the onboarding's remote config (e.g. `terms`,
    /// `privacy` keys). Used to resolve custom-action taps to in-app web view.
    @State private var remoteURLs: [String: URL] = [:]
    /// Drives `.fullScreenCover` for the in-app browser.
    @State private var webTarget: WebTarget?

    var body: some View {
        ZStack {
            Color.bg0.ignoresSafeArea()
            content
        }
        .task(id: phaseKey) { await load() }
        .task {
            // Prompt for push permission as soon as the Adapty onboarding
            // appears. iOS shows the system alert overlaying whatever's on
            // screen, so the user sees it together with the first onboarding
            // screen. Only fires when status is `.notDetermined` — no
            // re-prompts on subsequent launches.
            await NoJetLagAppDelegate.requestPushAuthorizationIfNeeded()
        }
        .fullScreenCover(item: $webTarget) { target in
            WebShellView(initialURL: target.url) { webTarget = nil }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .preparing:
            loadingView
        case .ready(let configuration):
            AdaptyOnboardingView(
                configuration: configuration,
                placeholder: { loadingView },
                onCloseAction: { _ in
                    onComplete()
                },
                onCustomAction: { action in
                    handleCustomAction(actionId: action.actionId)
                },
                onError: { error in
                    phase = .error(message(for: error))
                }
            )
            .ignoresSafeArea()
        case .error(let message):
            errorView(message: message)
        }
    }

    /// Adapty Onboarding Builder buttons configured as **Custom action** with
    /// an `actionId` matching a key in the onboarding's remote config will
    /// open that URL in our in-app `WebShellView`.
    ///
    /// Set up in Adapty Dashboard:
    ///   • Remote config rows: `terms` → URL, `privacy` → URL
    ///   • Buttons in the builder: action type **Custom**, Action ID `terms` /
    ///     `privacy` (matching the remote-config keys)
    private func handleCustomAction(actionId: String) {
        if let url = remoteURLs[actionId] {
            webTarget = WebTarget(url: url)
        } else {
            #if DEBUG
            print("Adapty onboarding custom action without resolvable URL: \(actionId)")
            #endif
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.amber)
            HStack(spacing: Spacing.sm) {
                PulsingDot(size: 6)
                Text("LOADING ONBOARDING")
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.textLo)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.advisoryRed, lineWidth: 1.5)
                    .frame(width: 48, height: 48)
                Text("!")
                    .font(Typography.display(28, weight: .semibold))
                    .foregroundStyle(Color.advisoryRed)
            }
            .padding(.bottom, Spacing.md)

            Text("ONBOARDING UNAVAILABLE")
                .font(Typography.mono(11, weight: .semibold))
                .trackedUppercase(1.6)
                .foregroundStyle(Color.advisoryRed)

            Text("We couldn't load the setup screens.")
                .font(Typography.body(17, weight: .semibold))
                .foregroundStyle(Color.textHi)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Text(message)
                .font(Typography.body(13))
                .foregroundStyle(Color.textMid)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, Spacing.xl)

            Spacer()

            Button(action: { phase = .preparing }) {
                Text("TRY AGAIN")
                    .trackedUppercase(1.4)
            }
            .buttonStyle(.instrument)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Async load

    /// Drives `.task(id:)` re-runs when phase resets to .preparing via TRY AGAIN.
    private var phaseKey: String {
        switch phase {
        case .preparing: return "preparing"
        case .ready:     return "ready"
        case .error:     return "error"
        }
    }

    private func load() async {
        guard case .preparing = phase else { return }
        do {
            // Wait for the shared Adapty + AdaptyUI activation Task — without
            // this, AdaptyUI.getOnboardingConfiguration throws error 4002.
            try await NoJetLagApp.adaptyActivation.value

            let onboarding = try await Adapty.getOnboarding(placementId: placementId)

            // Harvest remote-config URLs (terms, privacy, etc) so custom
            // actions can resolve their target page on tap.
            remoteURLs = Self.extractURLs(fromRemoteConfigOf: onboarding)

            // getOnboardingConfiguration is synchronous and throws.
            let configuration = try AdaptyUI.getOnboardingConfiguration(forOnboarding: onboarding)
            phase = .ready(configuration)
        } catch {
            phase = .error(message(for: error))
        }
    }

    /// Read string values from the onboarding's remote config and keep only
    /// those that parse as absolute http(s) URLs.
    ///
    /// **VERIFY:** the exact property name on `AdaptyOnboarding`'s remote
    /// config varies between SDK minor versions — `dictionary`, `data`, or
    /// `jsonString`. If the line below doesn't compile, swap to the right
    /// accessor; the rest of the function stays the same.
    private static func extractURLs(fromRemoteConfigOf onboarding: AdaptyOnboarding) -> [String: URL] {
        guard let dict = onboarding.remoteConfig?.dictionary as? [String: Any] else {
            return [:]
        }
        var urls: [String: URL] = [:]
        for (key, raw) in dict {
            guard let str = raw as? String,
                  let url = URL(string: str),
                  let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https"
            else { continue }
            urls[key] = url
        }
        return urls
    }

    private func message(for error: Error) -> String {
        if let adapty = error as? AdaptyError {
            return adapty.localizedDescription
        }
        return error.localizedDescription
    }

    // MARK: - Phase

    private enum Phase {
        case preparing
        case ready(AdaptyUI.OnboardingConfiguration)
        case error(String)
    }
}
