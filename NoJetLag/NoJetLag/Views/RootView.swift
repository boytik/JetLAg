import SwiftUI

/// Top-level switcher: shows onboarding if it hasn't been completed, otherwise
/// the main TabView (Now / Plan / Settings).
struct RootView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        if !state.hasCompletedOnboarding {
            OnboardingView()
                .transition(.opacity)
        } else {
            TabView {
                NowView()
                    .tabItem { Label("Now", systemImage: "circle.dashed") }
                PlanView()
                    .tabItem { Label("Plan", systemImage: "calendar") }
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape") }
            }
        }
    }
}
