import SwiftUI

/// Top-level switcher: shows onboarding if it hasn't been completed, otherwise
/// the main TabView (Now / Plan / Settings).
struct RootView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        ZStack {
            Color.bg0.ignoresSafeArea()
            if !state.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                TabView {
                    NowView()
                        .tabItem { Label("NOW", systemImage: "circle.dashed") }
                    PlanView()
                        .tabItem { Label("PLAN", systemImage: "calendar") }
                    SettingsView()
                        .tabItem { Label("SETTINGS", systemImage: "gearshape") }
                }
            }
        }
        .task {
            // Boot the ambient player once the root view is on screen.
            state.startAmbiencePlayback()
        }
    }
}
