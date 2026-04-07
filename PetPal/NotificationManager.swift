import UserNotifications

struct NotificationManager {

    /// Call once on launch to request alert/sound/badge permission.
    static func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// Schedules (or reschedules) a local notification for a care event.
    /// Fires at 9 AM on (dueDate − reminderDaysBefore days).
    /// No-ops if the trigger date is in the past or the event is already complete.
    static func schedule(for event: CareEvent, petName: String) {
        // Always cancel the previous notification for this event first
        cancel(id: event.notificationID)

        guard !event.isCompleted else { return }

        let triggerDate = Calendar.current.date(
            byAdding: .day, value: -event.reminderDaysBefore, to: event.dueDate
        ) ?? event.dueDate

        guard triggerDate > Date() else { return }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        components.hour = 9
        components.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "\(petName): \(event.name)"
        content.body = event.reminderDaysBefore == 0
            ? "Due today!"
            : "Due in \(event.reminderDaysBefore) day\(event.reminderDaysBefore == 1 ? "" : "s")"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: event.notificationID,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Cancels a pending notification by its stored ID.
    static func cancel(id: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [id])
    }
}
