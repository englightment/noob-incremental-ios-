import Foundation
import UserNotifications

/// Schedules a local "come back and collect" reminder for when the offline-progress cap will
/// be reached, so backgrounding the app doesn't silently waste potential earnings past the
/// cap. No server involved, just UNUserNotificationCenter — and permission is only requested
/// the first time this actually matters (the app backgrounding), not on cold launch.
enum OfflineReminderManager {
    private static let notificationID = "offline-cap-reminder"

    static func scheduleReminder(after duration: TimeInterval) {
        guard duration > 0 else { return }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    guard granted else { return }
                    schedule(after: duration, center: center)
                }
            case .authorized, .provisional:
                schedule(after: duration, center: center)
            default:
                break
            }
        }
    }

    static func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }

    private static func schedule(after duration: TimeInterval, center: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = "Your Noobs are maxed out!"
        content.body = "Offline earnings have hit their cap \u{2014} come back and collect your Oof."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
        center.add(request)
    }
}
