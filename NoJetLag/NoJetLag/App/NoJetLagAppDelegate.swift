import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

// =============================================================================
//  NoJetLagAppDelegate
//  -----------------------------------------------------------------------------
//  Hooks the app into:
//    • Firebase (FirebaseApp.configure on launch)
//    • UNUserNotificationCenter (foreground banner presentation, taps)
//    • FirebaseMessaging (APNs token forwarding, FCM token receipt)
//
//  After the FCM token arrives, the device is subscribed to topic "all" so
//  any push the backend sends to that topic reaches every install.
//
//  Wired into the SwiftUI app via `@UIApplicationDelegateAdaptor` in
//  `NoJetLagApp.swift`.
//
//  Requirements:
//    1. `GoogleService-Info.plist` is in the target.    ✓ (already present)
//    2. SPM packages: `FirebaseCore`, `FirebaseMessaging`. ✓ (already in)
//    3. Capabilities (Xcode → Signing & Capabilities):
//       - Push Notifications
//       - Background Modes → Remote notifications  (for silent push & topic delivery)
//    4. APNs key uploaded to Firebase Console → Project Settings → Cloud Messaging.
// =============================================================================

final class NoJetLagAppDelegate: NSObject,
    UIApplicationDelegate,
    UNUserNotificationCenterDelegate,
    MessagingDelegate
{
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // If the user previously authorised push, re-register for remote
        // notifications on every cold launch so APNs hands us a fresh token.
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
        return true
    }

    // MARK: - APNs token

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Forward the APNs device token to Firebase. Sandbox token in DEBUG
        // builds (TestFlight is also .prod; that's correct for TestFlight).
        #if DEBUG
        Messaging.messaging().setAPNSToken(deviceToken, type: .sandbox)
        #else
        Messaging.messaging().setAPNSToken(deviceToken, type: .prod)
        #endif
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        print("APNs registration failed: \(error)")
        #endif
    }

    // MARK: - Foreground / tap handlers

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notifications as banners even when the app is foreground.
        completionHandler([.banner, .badge, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Tap-handling hook. Inspect `response.notification.request.content.userInfo`
        // here to deep-link into the relevant screen when needed.
        completionHandler()
    }

    // MARK: - FCM token

    // MARK: - Permission prompt

    /// Asks the user to grant push permission, but only once. Subsequent calls
    /// are no-ops. Call after onboarding has completed so we don't interrupt
    /// the disclaimer / sleep-schedule flow.
    @MainActor
    static func requestPushAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            #if DEBUG
            print("Push authorization request failed: \(error)")
            #endif
        }
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken, !token.isEmpty else { return }

        // Cache locally for diagnostics or backend syncs.
        UserDefaults.standard.set(token, forKey: "fcmToken")

        // Subscribe every install to the broadcast topic. The backend can
        // send a push to "all" and reach the entire user base.
        Messaging.messaging().subscribe(toTopic: "all") { error in
            #if DEBUG
            if let error {
                print("FCM topic 'all' subscription failed: \(error)")
            } else {
                print("FCM subscribed to topic 'all' (token: \(token.prefix(12))…)")
            }
            #endif
        }
    }
}
