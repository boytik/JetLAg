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
//  Adapty host — REPLACE THIS BLOCK WITH THE REAL SDK CALL
// =============================================================================
//
//  When AdaptySDK is wired in code:
//    1. `import Adapty` and `import AdaptyUI` at the top of this file.
//    2. Activate the SDK once, in `NoJetLagApp.init()`:
//         Adapty.activate("YOUR_PUBLIC_SDK_KEY")
//    3. Replace the body of AdaptyOnboardingHost below with a
//       `UIViewControllerRepresentable` that fetches the onboarding view model
//       and presents `AdaptyUI.OnboardingViewController`. Wire the
//       `AdaptyOnboardingControllerDelegate` so the success callback calls
//       `onComplete()`.
//
//  Until then, this placeholder lets the gate work end-to-end visually:
//  it shows a clearly-labeled "ADAPTY · PLACEHOLDER" view with a Continue
//  button that fires `onComplete`. **Do not ship this to production.**
// =============================================================================

/// SwiftUI host for the Adapty onboarding view controller.
///
/// **TODO(adapty):** swap the body for a `UIViewControllerRepresentable` that
/// presents `AdaptyUI.OnboardingViewController`. Keep the `onComplete`
/// signature so the gate keeps working unchanged.
struct AdaptyOnboardingHost: View {
    let onComplete: () -> Void

    var body: some View {
        // ─── PLACEHOLDER START ──────────────────────────────────────────────
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack(spacing: Spacing.sm) {
                    PulsingDot(size: 6)
                    Text("ADAPTY · PLACEHOLDER")
                        .font(Typography.mono(10, weight: .semibold))
                        .trackedUppercase(1.6)
                        .foregroundStyle(Color.amber)
                }

                Text("Adapty onboarding goes here.")
                    .font(Typography.display(28, weight: .semibold))
                    .foregroundStyle(Color.textHi)
                    .tracking(-0.5)

                Text("This view will be replaced with `AdaptyUI.OnboardingViewController` once the SDK is wired. The gate, offline blocker, and downstream sleep-schedule sheet already work.")
                    .font(Typography.body(13))
                    .foregroundStyle(Color.textMid)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                InstrumentCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        SectionTag(text: "WIRING CHECKLIST")
                        Text("1. Adapty.activate(\"PUBLIC_KEY\") in NoJetLagApp.init()")
                        Text("2. Replace AdaptyOnboardingHost body with the OnboardingViewController representable")
                        Text("3. Call onComplete() from the Adapty delegate's finish callback")
                    }
                    .font(Typography.body(13))
                    .foregroundStyle(Color.textMid)
                }

                Spacer(minLength: Spacing.xl)

                Button(action: onComplete) {
                    Text("FINISH PLACEHOLDER")
                        .trackedUppercase(1.4)
                }
                .buttonStyle(.instrument)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xxl)
            .padding(.bottom, Spacing.xl)
        }
        // ─── PLACEHOLDER END ────────────────────────────────────────────────
    }
}

// =============================================================================
//  Offline blocker
// =============================================================================

/// Shown when the user has not yet seen Adapty onboarding AND is offline.
/// Auto-dismisses (via the gate's `isOnline` re-render) the moment a network
/// path becomes available.
struct OfflineBlockingView: View {
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
                Text("WAITING FOR NETWORK")
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.textLo)
            }
            .padding(.bottom, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Spacing.lg)
    }
}
