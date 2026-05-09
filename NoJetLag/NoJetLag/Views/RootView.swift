import SwiftUI

/// Top-level switcher with a hard, three-stage gate:
///
///   1. **Adapty onboarding gate** (offline → blocking screen).
///      Required before *any* part of the app is reachable.
///   2. **Native sleep-schedule sheet** (non-dismissable, save-only).
///   3. **Main TabView** (Now / Plan / Settings).
///
/// Both gate flags are persisted in `AppState`, so a user who completes
/// step 1 once never has to repeat it — even on subsequent offline launches.
struct RootView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        ZStack {
            Color.bg0.ignoresSafeArea()
            currentStage
        }
        .animation(.easeInOut(duration: 0.25), value: state.hasSeenAdaptyOnboarding)
        .animation(.easeInOut(duration: 0.25), value: state.hasSetSleepSchedule)
    }

    @ViewBuilder
    private var currentStage: some View {
        if !state.hasSeenAdaptyOnboarding {
            AdaptyOnboardingGate {
                state.hasSeenAdaptyOnboarding = true
            }
            .transition(.opacity)
        } else if !state.hasSetSleepSchedule {
            SleepScheduleSheet {
                // onComplete fires after state has been updated inside the sheet.
            }
            .transition(.opacity)
        } else {
            mainTabs
                .transition(.opacity)
        }
    }

    private var mainTabs: some View {
        TabView {
            NowView()
                .tabItem { Label("NOW", systemImage: "circle.dashed") }
            PlanView()
                .tabItem { Label("PLAN", systemImage: "calendar") }
            SettingsView()
                .tabItem { Label("SETTINGS", systemImage: "gearshape") }
        }
        // Boot the ambient player only once both gates have passed and the
        // tab bar appears — keeps the onboarding/disclaimer screens silent.
        .task {
            state.startAmbiencePlayback()
        }
    }
}
