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

    var body: some View {
        ZStack {
            Color.bg0.ignoresSafeArea()
            content
        }
        .task(id: phaseKey) { await load() }
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
                    handleCustomAction(action)
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

    /// Handles `Custom` button actions that the user wires up in the Adapty
    /// Onboarding Builder. The `actionId` is the string the user enters when
    /// configuring the button.
    ///
    /// To make a button trigger the iOS push permission prompt:
    ///   1. In Adapty Dashboard → Onboarding Builder → add a button.
    ///   2. Set its action to **Custom** with Action ID `allowNotifications`.
    ///   3. Tapping the button on the device will fire this handler, which
    ///      shows the system "Allow Notifications" prompt.
    private func handleCustomAction(_ action: AdaptyOnboardingsCustomAction) {
        switch action.actionId {
        case "allowNotifications":
            Task { @MainActor in
                await NoJetLagAppDelegate.requestPushAuthorizationIfNeeded()
            }
        default:
            #if DEBUG
            print("Unhandled Adapty onboarding custom action: \(action.actionId)")
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
            // getOnboardingConfiguration is synchronous and throws.
            let configuration = try AdaptyUI.getOnboardingConfiguration(forOnboarding: onboarding)
            phase = .ready(configuration)
        } catch {
            phase = .error(message(for: error))
        }
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
