import SwiftUI

// =============================================================================
//  Adapty onboarding gate
//  -----------------------------------------------------------------------------
//  Hard gate at first launch:
//    • If `hasSeenAdaptyOnboarding == false` → user must complete Adapty.
//    • Online → Adapty onboarding host is presented.
//    • Offline → blocking screen, retries automatically when connection returns.
//    • The flag flips to true ONLY through `onComplete` from the Adapty
//      delegate, so a kill-9 mid-flow forces the user back through next launch.
//
//  After this gate, the user lands on `SleepScheduleSheet` (which has its
//  own non-dismissable gate flag).
// =============================================================================

/// Top-level gate. Swaps between the Adapty host and the offline blocker
/// based on live network status from `NetworkMonitor.shared`.
struct AdaptyOnboardingGate: View {
    let onComplete: () -> Void
    @StateObject private var network = NetworkMonitor.shared

    var body: some View {
        ZStack {
            Color.bg0.ignoresSafeArea()
            if network.isOnline {
                AdaptyOnboardingHost(onComplete: onComplete)
                    .transition(.opacity)
            } else {
                OfflineBlockingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: network.isOnline)
    }
}

// =============================================================================
//  Adapty host — real implementation
// =============================================================================
//
//  Loads + presents the Adapty onboarding configured in the dashboard at the
//  placement ID `NoJetLagApp.adaptyOnboardingPlacementId`. All Adapty imports
//  live in `AdaptyOnboardingPresenter.swift` so this gate stays SDK-light.
// =============================================================================

/// SwiftUI host for the Adapty onboarding view controller.
struct AdaptyOnboardingHost: View {
    let onComplete: () -> Void

    var body: some View {
        AdaptyOnboardingPresenter(
            placementId: NoJetLagApp.adaptyOnboardingPlacementId,
            onComplete: onComplete
        )
    }
}

// =============================================================================
//  Offline blocker
// =============================================================================

/// Shown when the user has not yet seen Adapty onboarding AND is offline.
/// Auto-dismisses (via the gate's `isOnline` re-render) the moment a network
/// path becomes available, but also exposes a TRY AGAIN button so the user
/// can force a re-check on flaky networks.
struct OfflineBlockingView: View {
    @State private var isChecking: Bool = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            // Custom 1.5pt stroke instrument-style glyph (slashed circle).
            ZStack {
                Circle()
                    .stroke(Color.advisoryRed, style: StrokeStyle(lineWidth: 1.5))
                    .frame(width: 48, height: 48)
                Rectangle()
                    .fill(Color.advisoryRed)
                    .frame(width: 1.5, height: 56)
                    .rotationEffect(.degrees(45))
            }
            .padding(.bottom, Spacing.md)

            Text("CONNECTION REQUIRED")
                .font(Typography.mono(11, weight: .semibold))
                .trackedUppercase(1.6)
                .foregroundStyle(Color.advisoryRed)

            Text("Connect to the internet to continue setup.")
                .font(Typography.body(17, weight: .semibold))
                .foregroundStyle(Color.textHi)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Text("NoJetLag needs to load your initial setup once. After that, the app works fully offline.")
                .font(Typography.body(13))
                .foregroundStyle(Color.textMid)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.xl)

            Spacer()

            HStack(spacing: Spacing.sm) {
                PulsingDot(color: .advisoryRed, size: 6)
                Text(isChecking ? "CHECKING…" : "WAITING FOR NETWORK")
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.textLo)
            }

            Button(action: tryAgain) {
                Text(isChecking ? "CHECKING…" : "TRY AGAIN")
                    .trackedUppercase(1.4)
            }
            .buttonStyle(.instrument)
            .disabled(isChecking)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Spacing.lg)
    }

    private func tryAgain() {
        guard !isChecking else { return }
        isChecking = true
        NetworkMonitor.shared.recheck()
        // Small visual confirmation that we tried — if path is still down,
        // drop back to the idle state. If the path came back, the parent
        // gate transitions away and this view disappears anyway.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isChecking = false
        }
    }
}
