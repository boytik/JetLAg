import SwiftUI
import Combine
import WebKit
import UIKit

// =============================================================================
//  WebShellView
//  -----------------------------------------------------------------------------
//  Full-screen in-app browser used for article links and any URL the app
//  doesn't want to hand off to Safari.
//
//  Layout, mirroring the Foltey/Stellara pattern:
//
//    PORTRAIT
//      [chrome bar — notch height, bg1]
//      [WebSurface, padded top by safe-top, bottom by 56pt rail]
//      [bottom rail — 56pt, bg1, extends to screen edge — NO bottom safe area]
//
//    LANDSCAPE (notch detected via leading vs trailing safe inset)
//      [chrome bar — notch-side filler]
//      [WebSurface, padded by notch inset and rail thickness]
//      [side rail — 56pt vertical, on the side OPPOSITE the notch]
//
//  Rotation is permitted for the lifetime of this view by widening the
//  AppDelegate's `supportedOrientations` to `.all`. On dismiss, the mask is
//  restored to `.portrait` so the rest of the app stays portrait-locked.
//
//  Safe-area insets are read directly from the active `UIWindow` because
//  SwiftUI's `GeometryProxy.safeAreaInsets` returns zeros inside
//  `fullScreenCover` on several iOS versions.
// =============================================================================

struct WebShellView: View {
    /// Original (uncached) URL from the source — e.g. the value the Adapty
    /// remote config returned. Used to compute the rescue URL on failure.
    /// May equal `initialURL` if there's no cached / saved URL on file.
    let baseURL: URL
    /// URL to load first. May differ from `baseURL` when a previous successful
    /// load has populated `WebRecoveryStore.savedURL`.
    let initialURL: URL
    let onDismiss: () -> Void

    @StateObject private var pilot = WebPilot()
    @StateObject private var insets = WindowInsetVault()

    /// The URL currently driving the WKWebView. Mutated internally on
    /// failure-with-rescue so the cover stays mounted across retries — the
    /// presenter never sees the swap.
    @State private var currentURL: URL
    /// True after we've already swapped to the rescue URL. A second failure
    /// now dismisses the cover instead of looping.
    @State private var didTryRescue: Bool = false

    init(baseURL: URL,
         initialURL: URL,
         onDismiss: @escaping () -> Void) {
        self.baseURL = baseURL
        self.initialURL = initialURL
        self.onDismiss = onDismiss
        _currentURL = State(initialValue: initialURL)
    }

    var body: some View {
        GeometryReader { geo in
            shell(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .background(
            // Invisible probe attaches to the active window and feeds the
            // vault every time layout settles.
            InsetWatcher(vault: insets).allowsHitTesting(false)
        )
        .task {
            #if DEBUG
            print("[orient] WebShellView.task fired")
            #endif
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            NoJetLagAppDelegate.permitOrientations(.all)
            insets.refresh()
        }
        .onAppear {
            #if DEBUG
            print("[orient] WebShellView.onAppear fired")
            #endif
            // Belt-and-suspenders — `.task` and `.onAppear` both fire on
            // appearance but at slightly different points in the lifecycle;
            // doing it twice is a no-op when mask is already `.all`.
            NoJetLagAppDelegate.permitOrientations(.all)
        }
        .onDisappear {
            #if DEBUG
            print("[orient] WebShellView.onDisappear fired")
            #endif
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
            NoJetLagAppDelegate.permitOrientations(.portrait)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            insets.refresh()
            // Some devices need a couple of refresh ticks for new insets to settle.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { insets.refresh() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { insets.refresh() }
        }
    }

    // MARK: - Layout

    private static let railThickness: CGFloat = 56

    @ViewBuilder
    private func shell(width: CGFloat, height: CGFloat) -> some View {
        let edges = insets.edges
        let isPortrait = height >= width
        let notchOnLeading = !isPortrait && Self.notchAnchoredLeading(edges: edges)

        let webPadding: EdgeInsets = {
            if isPortrait {
                // Notch padding on top, rail height on bottom. NO bottom
                // safe area — the rail covers the home indicator zone.
                return EdgeInsets(top: edges.top,
                                  leading: 0,
                                  bottom: Self.railThickness,
                                  trailing: 0)
            }
            if notchOnLeading {
                // Notch on left → rail on right.
                return EdgeInsets(top: 0,
                                  leading: edges.left,
                                  bottom: 0,
                                  trailing: Self.railThickness)
            }
            // Notch on right → rail on left.
            return EdgeInsets(top: 0,
                              leading: Self.railThickness,
                              bottom: 0,
                              trailing: edges.right)
        }()

        ZStack(alignment: .topLeading) {
            Color.bg1.ignoresSafeArea()

            WebSurface(
                url: currentURL,
                pilot: pilot,
                onFinalURL: handleFinalURL,
                onFailure: { handleFailure(loadedURL: currentURL) }
            )
            // Forcing remount on URL change keeps the WKWebView's coordinator
            // state (didCaptureFinalForCurrentLoad, etc.) clean per attempt.
            .id(currentURL.absoluteString)
            .padding(webPadding)

            chromeBar(isPortrait: isPortrait, notchOnLeading: notchOnLeading, edges: edges)

            railBar(isPortrait: isPortrait, notchOnLeading: notchOnLeading)
        }
        .frame(width: width, height: height, alignment: .topLeading)
    }

    // MARK: - Final-URL capture & failure recovery

    /// Successful main-frame load — cache the final URL (post redirects)
    /// in WebRecoveryStore so the next privacy tap can skip the round-trip.
    private func handleFinalURL(_ final: URL) {
        #if DEBUG
        print("[web] ← server reached, final URL = \(final.absoluteString)")
        #endif
        WebRecoveryStore.shared.captureFinal(final)
    }

    /// Retry-once recovery on a failed load.
    ///
    /// First failure:
    ///   • Compute rescue via `syntheticURL(forBase:)` (or fall back to base)
    ///     without mutating the store.
    ///   • If the rescue equals what we just tried, give up — `markFailed()`
    ///     and dismiss.
    ///   • Otherwise swap `currentURL` to the rescue. The cover stays
    ///     mounted; only the WebSurface is recreated by `.id()`.
    ///
    /// Second consecutive failure: terminal — `markFailed()` and dismiss.
    ///
    /// `markFailed()` flips `savedURL` to nil, which the RootView gate
    /// reads to consider onboarding passed even if the page never loaded.
    private func handleFailure(loadedURL url: URL) {
        let store = WebRecoveryStore.shared

        #if DEBUG
        print("[web] ✗ load failed for \(url.absoluteString) — didTryRescue=\(didTryRescue)")
        #endif

        guard !didTryRescue else {
            #if DEBUG
            print("[web] terminal failure → markFailed() + dismiss")
            #endif
            store.markFailed()
            onDismiss()
            return
        }

        // Pure read — `syntheticURL` is `<baseURL>/<pathID>` if a pathID is
        // on file, otherwise nil. Fall back to the bare baseURL when no
        // synthetic is available.
        let rescue = store.syntheticURL(forBase: baseURL) ?? baseURL
        #if DEBUG
        print("[web] computed rescue URL = \(rescue.absoluteString) (baseURL=\(baseURL.absoluteString), pathID=\(store.pathID ?? "nil"))")
        #endif

        guard rescue.absoluteString != url.absoluteString else {
            #if DEBUG
            print("[web] rescue == failing URL → no point retrying → markFailed() + dismiss")
            #endif
            store.markFailed()
            onDismiss()
            return
        }

        #if DEBUG
        print("[web] swapping currentURL to rescue \(rescue.absoluteString)")
        #endif
        didTryRescue = true
        currentURL = rescue
    }

    /// Notch-side filler — same color as the rail so the chrome reads as one
    /// continuous instrument frame around the web content.
    @ViewBuilder
    private func chromeBar(isPortrait: Bool, notchOnLeading: Bool, edges: UIEdgeInsets) -> some View {
        if isPortrait {
            Color.bg1
                .frame(height: edges.top)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else if notchOnLeading {
            Color.bg1
                .frame(width: edges.left)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else {
            Color.bg1
                .frame(width: edges.right)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func railBar(isPortrait: Bool, notchOnLeading: Bool) -> some View {
        if isPortrait {
            navBarHorizontal
                .frame(height: Self.railThickness)
                .background(Color.bg1)
                .overlay(alignment: .top) { Hairline() }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        } else if notchOnLeading {
            navBarVertical
                .background(Color.bg1)
                .overlay(alignment: .leading) { verticalHairline }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        } else {
            navBarVertical
                .background(Color.bg1)
                .overlay(alignment: .trailing) { verticalHairline }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private var verticalHairline: some View {
        Rectangle()
            .fill(Color.stroke)
            .frame(width: 1)
    }

    // MARK: - Notch-side detection (three-tier fallback)
    //
    // Insets sometimes lag behind the orientation event when the user rotates,
    // so we layer three signals — the most reliable one wins.
    //
    //   1. `safeAreaLayoutGuide.layoutFrame` measured against window bounds —
    //      most accurate, reflects the true visible inset on each side.
    //   2. `UIWindow.safeAreaInsets.left` vs `.right` — fast but stale during
    //      rotation transitions.
    //   3. `UIDevice.current.orientation` — last-resort, only used when the
    //      first two are inconclusive.

    @MainActor
    private static func notchAnchoredLeading(edges: UIEdgeInsets) -> Bool {
        if let gaps = lateralSafeGaps(),
           abs(gaps.fore - gaps.aft) > 0.32 {
            return gaps.fore > gaps.aft
        }
        if edges.left > edges.right + 0.5 { return true }
        if edges.right > edges.left + 0.5 { return false }
        switch activeFacing() {
        case .landscapeLeft:  return false   // notch on right side of screen
        case .landscapeRight: return true    // notch on left side of screen
        default:              return false
        }
    }

    @MainActor
    private static func lateralSafeGaps() -> (fore: CGFloat, aft: CGFloat)? {
        guard let window = WindowInsetVault.activeWindow() else { return nil }
        let bounds = window.bounds
        let frame = window.safeAreaLayoutGuide.layoutFrame
        return (frame.minX, bounds.width - frame.maxX)
    }

    @MainActor
    private static func activeFacing() -> UIInterfaceOrientation {
        if let scene = WindowInsetVault.activeWindow()?.windowScene,
           scene.interfaceOrientation != .unknown {
            return scene.interfaceOrientation
        }
        switch UIDevice.current.orientation {
        case .landscapeLeft:  return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        default:              return .unknown
        }
    }

    // MARK: - Nav rail buttons

    private var navBarHorizontal: some View {
        HStack(spacing: 0) {
            ForEach(navButtons) { btn in
                navButton(btn).frame(maxWidth: .infinity)
            }
        }
    }

    private var navBarVertical: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            ForEach(navButtons) { btn in
                navButton(btn).frame(maxHeight: 64)
            }
            Spacer(minLength: 0)
        }
        .frame(width: Self.railThickness)
    }

    private func navButton(_ btn: NavButtonModel) -> some View {
        Button(action: btn.action) {
            Image(systemName: btn.symbol)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .disabled(!btn.enabled)
        .foregroundStyle(btn.tint)
        .buttonStyle(.plain)
    }

    private var navButtons: [NavButtonModel] {
        let active = Color.amber
        let muted = Color.amber.opacity(0.30)
        let close = Color.textMid

        return [
            NavButtonModel(id: "back", symbol: "chevron.backward",
                           enabled: pilot.canGoBack,
                           tint: pilot.canGoBack ? active : muted) { pilot.goBack() },
            NavButtonModel(id: "forward", symbol: "chevron.forward",
                           enabled: pilot.canGoForward,
                           tint: pilot.canGoForward ? active : muted) { pilot.goForward() },
            NavButtonModel(id: "reload", symbol: "arrow.clockwise",
                           enabled: true, tint: active) { pilot.reload() },
            NavButtonModel(id: "home", symbol: "house",
                           enabled: true, tint: active) { goHome() },
            NavButtonModel(id: "close", symbol: "xmark",
                           enabled: true, tint: close) { onDismiss() }
        ]
    }

    private func goHome() {
        if currentURL.absoluteString != initialURL.absoluteString {
            currentURL = initialURL
        } else {
            pilot.load(initialURL)
        }
    }
}

private struct NavButtonModel: Identifiable {
    let id: String
    let symbol: String
    let enabled: Bool
    let tint: Color
    let action: () -> Void
}

// =============================================================================
//  WindowInsetVault — observable holder for the active UIWindow's safe-area
//  insets. SwiftUI's `GeometryProxy.safeAreaInsets` returns zero on multiple
//  iOS versions when the host view ignores the safe area inside a
//  fullScreenCover, so we read directly from UIKit.
// =============================================================================

@MainActor
final class WindowInsetVault: ObservableObject {
    @Published private(set) var edges: UIEdgeInsets = .zero

    func ingest(_ window: UIWindow) {
        let live = window.safeAreaInsets
        if !Self.almostEqual(edges, live) { edges = live }
    }

    func refresh() {
        guard let window = Self.activeWindow() else { return }
        ingest(window)
    }

    static func activeWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let prime = scenes.first(where: {
            $0.activationState == .foregroundActive && $0.windows.contains(where: \.isKeyWindow)
        })
        let scene = prime
            ?? scenes.first(where: { $0.windows.contains(where: \.isKeyWindow) })
            ?? scenes.first
        return scene?.windows.first(where: \.isKeyWindow) ?? scene?.windows.first
    }

    private static func almostEqual(_ a: UIEdgeInsets, _ b: UIEdgeInsets) -> Bool {
        let tol: CGFloat = 0.25
        return abs(a.top - b.top) < tol
            && abs(a.left - b.left) < tol
            && abs(a.bottom - b.bottom) < tol
            && abs(a.right - b.right) < tol
    }
}

private struct InsetWatcher: UIViewRepresentable {
    let vault: WindowInsetVault

    func makeUIView(context: Context) -> Probe {
        let probe = Probe()
        probe.deliver = { [weak vault] window in
            guard let vault else { return }
            Task { @MainActor in vault.ingest(window) }
        }
        return probe
    }

    func updateUIView(_ probe: Probe, context: Context) {
        probe.deliver = { [weak vault] window in
            guard let vault else { return }
            Task { @MainActor in vault.ingest(window) }
        }
        probe.setNeedsLayout()
    }

    final class Probe: UIView {
        var deliver: ((UIWindow) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let window { deliver?(window) }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            if let window { deliver?(window) }
        }
    }
}

// =============================================================================
//  WebPilot — observable proxy that the SwiftUI rail uses to drive the
//  underlying WKWebView. Owned by the SwiftUI view; the WebSurface attaches
//  the live WKWebView reference once mounted.
// =============================================================================

@MainActor
final class WebPilot: ObservableObject {
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false

    weak var webView: WKWebView?

    func sync() {
        guard let webView else { return }
        if canGoBack    != webView.canGoBack    { canGoBack    = webView.canGoBack }
        if canGoForward != webView.canGoForward { canGoForward = webView.canGoForward }
    }

    func goBack()    { webView?.goBack() }
    func goForward() { webView?.goForward() }
    func reload()    { webView?.reload() }

    func load(_ url: URL) {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        webView?.load(request)
    }
}

// =============================================================================
//  WebSurface — UIViewRepresentable wrapping WKWebView.
// =============================================================================

private struct WebSurface: UIViewRepresentable {
    let url: URL
    let pilot: WebPilot
    let onFinalURL: ((URL) -> Void)?
    let onFailure: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinalURL: onFinalURL, onFailure: onFailure)
    }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.defaultWebpagePreferences.allowsContentJavaScript = true

        let view = WKWebView(frame: .zero, configuration: cfg)
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.backgroundColor = UIColor(Color.bg0)
        view.isOpaque = false
        view.scrollView.backgroundColor = UIColor(Color.bg0)
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator

        let refresh = UIRefreshControl()
        refresh.tintColor = UIColor(Color.amber)
        refresh.addTarget(context.coordinator,
                          action: #selector(Coordinator.handleRefresh(_:)),
                          for: .valueChanged)
        view.scrollView.refreshControl = refresh

        context.coordinator.attach(view: view, pilot: pilot)
        #if DEBUG
        print("[web] → loading \(url.absoluteString)")
        #endif
        view.load(URLRequest(url: url))
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url?.absoluteString != url.absoluteString {
            uiView.load(URLRequest(url: url))
        }
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.detach()
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        /// Watchdog timeout for the initial page load. WKWebView can sit on
        /// a hung connection for tens of seconds (or forever in some
        /// hostile-offline scenarios) without firing didFail, so we add our
        /// own deadline. Tuned for a privacy-page-style document — a value
        /// big enough not to cut off real loads on slow networks, small
        /// enough that the user doesn't stare at a dark screen.
        private static let loadWatchdogSeconds: TimeInterval = 8

        private weak var view: WKWebView?
        private weak var pilot: WebPilot?
        private var observations: [NSKeyValueObservation] = []

        /// True once we've fired `onFinalURL` for the current load. After
        /// this, all failure-like signals (4xx/5xx, didFail, watchdog) are
        /// IGNORED — the user is browsing inside the page now, and a JS-
        /// driven sub-navigation returning 4xx is not a load failure.
        private var didCaptureFinalForCurrentLoad = false

        /// True after we've fired `onFailure` for the current load — guards
        /// against any second failure signal from late delegate callbacks.
        private var didFireFailureForCurrentLoad = false

        /// Cancellable handle for the load watchdog. Replaced when a new
        /// load starts; cancelled on capture or terminal failure.
        private var watchdog: DispatchWorkItem?

        var onFinalURL: ((URL) -> Void)?
        var onFailure: (() -> Void)?

        init(onFinalURL: ((URL) -> Void)?, onFailure: (() -> Void)?) {
            self.onFinalURL = onFinalURL
            self.onFailure = onFailure
            super.init()
        }

        func attach(view: WKWebView, pilot: WebPilot) {
            self.view = view
            self.pilot = pilot
            pilot.webView = view
            installObservers(on: view)
            startWatchdog()
        }

        func detach() {
            observations.forEach { $0.invalidate() }
            observations.removeAll()
            cancelWatchdog()
        }

        @objc func handleRefresh(_ sender: UIRefreshControl) {
            view?.reload()
        }

        private func endRefreshing() {
            view?.scrollView.refreshControl?.endRefreshing()
        }

        private func installObservers(on view: WKWebView) {
            let trigger: (Any, Any) -> Void = { [weak self] _, _ in
                Task { @MainActor [weak self] in self?.pilot?.sync() }
            }
            observations = [
                view.observe(\.canGoBack,    options: [.new, .initial], changeHandler: trigger),
                view.observe(\.canGoForward, options: [.new, .initial], changeHandler: trigger),
                view.observe(\.url,          options: [.new],            changeHandler: trigger)
            ]
        }

        // MARK: Watchdog

        private func startWatchdog() {
            cancelWatchdog()
            let item = DispatchWorkItem { [weak self] in
                guard let self else { return }
                guard !self.didCaptureFinalForCurrentLoad,
                      !self.didFireFailureForCurrentLoad else { return }
                #if DEBUG
                print("[web] watchdog fired (\(Self.loadWatchdogSeconds)s) — no didFinish/didFail → treating as failure")
                #endif
                self.fireFailure()
            }
            watchdog = item
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.loadWatchdogSeconds, execute: item)
        }

        private func cancelWatchdog() {
            watchdog?.cancel()
            watchdog = nil
        }

        /// Single funnel for declaring the current load failed. Idempotent.
        private func fireFailure() {
            guard !didFireFailureForCurrentLoad else { return }
            didFireFailureForCurrentLoad = true
            cancelWatchdog()
            endRefreshing()
            onFailure?()
        }

        // MARK: Navigation delegate

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            endRefreshing()
            Task { @MainActor in pilot?.sync() }
            // Capture final URL once per load, only for http(s) main-frame.
            if !didCaptureFinalForCurrentLoad,
               let url = webView.url,
               let scheme = url.scheme?.lowercased(),
               scheme == "http" || scheme == "https"
            {
                didCaptureFinalForCurrentLoad = true
                cancelWatchdog()
                #if DEBUG
                print("[web] didFinish OK → final \(url.absoluteString)")
                #endif
                onFinalURL?(url)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handleFailure(error, label: "didFail")
        }

        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            handleFailure(error, label: "didFailProvisionalNavigation")
        }

        /// HTTP status check — treat 4xx/5xx main-frame responses as load
        /// failures, but ONLY before we've successfully captured a final URL.
        /// After that, the user is browsing and a 4xx in a sub-flow is
        /// normal page behavior, not a "load failed" signal.
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationResponse: WKNavigationResponse,
                     decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if navigationResponse.isForMainFrame,
               let http = navigationResponse.response as? HTTPURLResponse {
                #if DEBUG
                let phase = didCaptureFinalForCurrentLoad ? "post-final" : "initial"
                print("[web] response status \(http.statusCode) [\(phase)] for \(http.url?.absoluteString ?? "?")")
                #endif
                if !didCaptureFinalForCurrentLoad,
                   (400...599).contains(http.statusCode) {
                    decisionHandler(.cancel)
                    #if DEBUG
                    print("[web] HTTP \(http.statusCode) treated as failure")
                    #endif
                    fireFailure()
                    return
                }
            }
            decisionHandler(.allow)
        }

        private func handleFailure(_ error: Error, label: String) {
            // Ignore user-initiated cancellations (e.g. tapping a new link
            // before the previous one finished loading).
            let ns = error as NSError
            guard ns.code != NSURLErrorCancelled else { return }
            #if DEBUG
            print("[web] \(label) → \(ns.domain) code=\(ns.code) — \(ns.localizedDescription)")
            #endif
            // After a successful capture, in-page navigation errors are
            // normal browsing — don't treat them as load failures.
            guard !didCaptureFinalForCurrentLoad else { return }
            fireFailure()
        }

        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
    }
}

// =============================================================================
//  WebTarget — Identifiable wrapper passed through `.fullScreenCover(item:)`.
//  Carries BOTH the URL to load first (`url`) and the original base URL
//  (`baseURL`) so the WebShellView can compute a rescue URL on its own
//  without going back through the presenter.
//
//  `id` is a UUID — stable per presentation. Don't reassign the binding
//  with a new WebTarget while the cover is open; that'd dismiss & re-present.
// =============================================================================

struct WebTarget: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let baseURL: URL
}
