import SwiftUI
import FirebaseCore
import UserNotifications

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                  @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Set notification delegate here (runs before SwiftUI body)
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        return true
    }
}

// MARK: - Root App
@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var accountManager = AccountManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(accountManager)
                .onAppear {
                    // Ask permission early (optional)
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        if let error = error {
                            print("❌ Notification permission error:", error.localizedDescription)
                        } else {
                            print("✅ Notification permission granted:", granted)
                        }
                    }
                }
        }
    }
}

