import SwiftUI

// Kept as a thin alias so any existing `ContentView()` previews / references
// from the Xcode template continue to compile. RootView holds the real top-level UI.
struct ContentView: View {
    var body: some View { RootView() }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
