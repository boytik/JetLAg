import SwiftUI

@main
struct NoJetLagApp: App {
    @StateObject private var state = AppState.load()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
        }
    }
}
