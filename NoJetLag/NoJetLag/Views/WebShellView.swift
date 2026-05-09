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
//  Layout (portrait-only — NoJetLag is locked to portrait):
//    • Top notch safe area is respected (web content does not draw under it).
//    • Web content fills the rest of the screen.
//    • Bottom rail (56 pt + home-indicator extension) holds five icon buttons:
//      back · forward · reload · home · close.
//
//  Use it like:
//
//      @State private var openURL: URL?
//      ...
//      .fullScreenCover(item: $openURL) { url in
//          WebShellView(initialURL: url) { openURL = nil }
//      }
//
//  `initialURL` is also the "home" target — tapping the house icon returns the
//  user to that page.
// =============================================================================

struct WebShellView: View {
    let initialURL: URL
    let onDismiss: () -> Void

    @StateObject private var pilot = WebPilot()
    @State private var currentURL: URL

    init(initialURL: URL, onDismiss: @escaping () -> Void) {
        self.initialURL = initialURL
        self.onDismiss = onDismiss
        _currentURL = State(initialValue: initialURL)
    }

    var body: some View {
        ZStack {
            Color.bg0.ignoresSafeArea()
            VStack(spacing: 0) {
                // WKWebView. Top safe area is preserved by the parent VStack
                // (which sits inside the regular safe area), so the notch
                // doesn't overlap the page.
                WebSurface(url: currentURL, pilot: pilot)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                navBar
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Bottom rail

    private var navBar: some View {
        HStack(spacing: 0) {
            navButton(symbol: "chevron.backward",
                      enabled: pilot.canGoBack,
                      tint: .amber) { pilot.goBack() }
            navButton(symbol: "chevron.forward",
                      enabled: pilot.canGoForward,
                      tint: .amber) { pilot.goForward() }
            navButton(symbol: "arrow.clockwise",
                      enabled: true,
                      tint: .amber) { pilot.reload() }
            navButton(symbol: "house",
                      enabled: true,
                      tint: .amber) { goHome() }
            navButton(symbol: "xmark",
                      enabled: true,
                      tint: .textMid) { onDismiss() }
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(
            Color.bg1
                .overlay(alignment: .top) { Hairline() }
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func navButton(symbol: String,
                           enabled: Bool,
                           tint: Color,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .foregroundStyle(enabled ? tint : Color.textLo.opacity(0.4))
        .buttonStyle(.plain)
    }

    private func goHome() {
        if currentURL.absoluteString != initialURL.absoluteString {
            currentURL = initialURL
        } else {
            pilot.load(initialURL)
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

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.defaultWebpagePreferences.allowsContentJavaScript = true

        let view = WKWebView(frame: .zero, configuration: cfg)
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.contentInsetAdjustmentBehavior = .automatic
        view.backgroundColor = UIColor(Color.bg0)
        view.isOpaque = false
        view.scrollView.backgroundColor = UIColor(Color.bg0)
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator

        // Pull-to-refresh in the cockpit-night palette.
        let refresh = UIRefreshControl()
        refresh.tintColor = UIColor(Color.amber)
        refresh.addTarget(context.coordinator,
                          action: #selector(Coordinator.handleRefresh(_:)),
                          for: .valueChanged)
        view.scrollView.refreshControl = refresh

        context.coordinator.attach(view: view, pilot: pilot)
        view.load(URLRequest(url: url))
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Reload only if the SwiftUI-owned URL drifted away from the page in
        // the WebView (e.g. user tapped Home).
        if uiView.url?.absoluteString != url.absoluteString {
            uiView.load(URLRequest(url: url))
        }
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.detach()
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private weak var view: WKWebView?
        private weak var pilot: WebPilot?
        private var observations: [NSKeyValueObservation] = []

        func attach(view: WKWebView, pilot: WebPilot) {
            self.view = view
            self.pilot = pilot
            pilot.webView = view
            installObservers(on: view)
        }

        func detach() {
            observations.forEach { $0.invalidate() }
            observations.removeAll()
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

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            endRefreshing()
            Task { @MainActor in pilot?.sync() }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            endRefreshing()
        }

        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            endRefreshing()
        }

        // Open target=_blank links inline rather than dropping them.
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
//  Tiny Identifiable URL wrapper so callers can present via
//  `.fullScreenCover(item:)` without retroactively conforming URL itself.
//
//      @State private var webTarget: WebTarget?
//      .fullScreenCover(item: $webTarget) { target in
//          WebShellView(initialURL: target.url) { webTarget = nil }
//      }
// =============================================================================

struct WebTarget: Identifiable, Hashable {
    let url: URL
    var id: String { url.absoluteString }
}
