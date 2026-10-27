import Foundation
import UserNotifications

enum NotificationService {
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch { return false }
    }

    static func schedule(title: String, body: String, date: Date, identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let interval = max(5, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func scheduleMorningDigest() {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        let content = UNMutableNotificationContent()
        content.title = "TradeSense morning digest"
        content.body = "Review your watchlist and today's signals. Demo signals are illustrative, not financial advice."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "tradesense.morning.digest", content: content, trigger: trigger))
    }
}
