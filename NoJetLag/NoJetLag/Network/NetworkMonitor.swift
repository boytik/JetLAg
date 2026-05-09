import Foundation
import Network
import Combine

/// Lightweight wrapper around `NWPathMonitor` that publishes connectivity
/// state on the main queue. Used by the Adapty onboarding gate to swap
/// between the Adapty host view and the offline-blocker.
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    /// True when the device has any usable network path (Wi-Fi, cellular, etc).
    @Published private(set) var isOnline: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.nojetlag.networkmonitor")

    private init() {
        // Start with the current path snapshot so we don't briefly flash an
        // offline state on launch when the user actually has connectivity.
        let initial = monitor.currentPath
        self.isOnline = (initial.status == .satisfied)

        monitor.pathUpdateHandler = { [weak self] path in
            let online = (path.status == .satisfied)
            DispatchQueue.main.async {
                guard let self = self else { return }
                if self.isOnline != online {
                    self.isOnline = online
                }
            }
        }
        monitor.start(queue: queue)
    }

    /// Force a synchronous re-evaluation of the current network path.
    /// `NWPathMonitor` already pushes updates automatically, but a manual
    /// recheck is useful behind a "Try again" button — it gives the user
    /// agency on flaky networks where the monitor may have missed a flap.
    func recheck() {
        let online = monitor.currentPath.status == .satisfied
        DispatchQueue.main.async {
            if self.isOnline != online {
                self.isOnline = online
            } else {
                // Trigger objectWillChange so the view re-renders even when
                // the value didn't change — gives visual feedback on the tap.
                self.objectWillChange.send()
            }
        }
    }

    deinit {
        monitor.cancel()
    }
}
