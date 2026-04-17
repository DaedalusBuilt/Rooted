import SwiftUI
import UserNotifications
struct ContentView: View {
    @State private var showingAccount = false
    
    var body: some View {
        TabView {
            NavigationView {
                NatureQuestView()
                    .navigationTitle("Quests")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingAccount = true
                            } label: {
                                Image(systemName: "person.crop.circle")
                                    .imageScale(.large)
                            }
                        }
                    }
            }
            .tabItem { Label("Quests", systemImage: "leaf") }

            NavigationView {
                NatureMapView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingAccount = true
                            } label: {
                                Image(systemName: "person.crop.circle")
                                    .imageScale(.large)
                            }
                        }
                    }
            }
            .tabItem { Label("Map", systemImage: "map") }

            NavigationView {
                JournalView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingAccount = true
                            } label: {
                                Image(systemName: "person.crop.circle")
                                    .imageScale(.large)
                            }
                        }
                    }
            }
            .tabItem { Label("Journal", systemImage: "camera") }

            NavigationView {
                MindfulnessView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingAccount = true
                            } label: {
                                Image(systemName: "person.crop.circle")
                                    .imageScale(.large)
                            }
                        }
                    }
            }
            .tabItem { Label("Calm", systemImage: "wind") }

            NavigationView {
                HabitsView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingAccount = true
                            } label: {
                                Image(systemName: "person.crop.circle")
                                    .imageScale(.large)
                            }
                        }
                    }
            }
            .tabItem { Label("Habits", systemImage: "checkmark.circle") }
        }
        .sheet(isPresented: $showingAccount) {
            AccountView()
                // .environmentObject(accountManager)
        }
    }
}


import Foundation
import UserNotifications
import UIKit

final class NotificationManager: NSObject {
    static let shared = NotificationManager()
    private override init() { super.init() }

    // Must call early (AppDelegate or onAppear)
    func registerDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }

    // Request permission (calls completion on main thread)
    func requestPermission(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ requestAuthorization error:", error.localizedDescription)
            }
            DispatchQueue.main.async { completion(granted) }
        }
    }

    // Daily repeating notification (uses Calendar.current/time zone)
    func scheduleDailyNotification(title: String? = nil,
                                   body: String? = nil,
                                   hour: Int = 16,
                                   minute: Int = 12,
                                   identifier: String? = nil) {
        requestPermission { granted in
            guard granted else {
                print("❌ Notifications permission not granted. Ask user to enable them in Settings.")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = title ?? "Time to Journal ✍️"
            content.body  = body  ?? "Write down one thought, memory, or reflection for today."
            content.sound = .default

            var dc = DateComponents()
            dc.calendar = Calendar.current
            dc.timeZone = TimeZone.current
            dc.hour = hour
            dc.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            let id = identifier ?? "daily_notification_\(hour)_\(minute)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error scheduling notification:", error.localizedDescription)
                    } else {
                        print("✅ Scheduled notification '\(id)' at \(hour):\(String(format: "%02d", minute)) (repeats daily)")
                        self.printPendingRequests()
                    }
                }
            }
        }
    }

    // Fast test helper: schedule a one-off notification in N seconds
    func scheduleTestNotification(in seconds: TimeInterval = 10) {
        requestPermission { granted in
            guard granted else { print("❌ Permission denied for test"); return }
            let content = UNMutableNotificationContent()
            content.title = "Test Notification"
            content.body = "This should appear in \(Int(seconds)) seconds."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
            let id = "test_\(Date().timeIntervalSince1970)"
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trigger)) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ test schedule error:", error.localizedDescription)
                    } else {
                        print("✅ Test scheduled id: \(id)")
                        self.printPendingRequests()
                    }
                }
            }
        }
    }

    func printPendingRequests() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("Pending notifications (\(requests.count)):")
            for r in requests {
                print(" - \(r.identifier)  trigger:\(String(describing: r.trigger))")
            }
        }
    }

    // Convenience: open app settings if user denied notifications earlier
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    // show banner even if app is foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                    @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("📣 User tapped notification:", response.notification.request.identifier)
        completionHandler()
    }
}




#Preview {
    ContentView()
}

