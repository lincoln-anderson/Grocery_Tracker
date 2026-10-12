//
//  ExpirationReminderScheduler.swift
//  Grocery Tracker
//

import Foundation
import UserNotifications

enum ExpirationReminderSchedulerError: Error {
    case notificationsNotAuthorized
}

struct ExpirationReminderDetails: Sendable {
    let itemName: String
    let expirationDate: Date
    let daysBefore: Int
}

enum ExpirationReminderScheduler {
    static func schedule(
        _ details: ExpirationReminderDetails,
        requestingAuthorizationIfNeeded: Bool = false
    ) async throws -> String {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let isAuthorized: Bool

        if settings.authorizationStatus == .notDetermined && requestingAuthorizationIfNeeded {
            isAuthorized = try await center.requestAuthorization(options: [.alert, .sound])
        } else {
            isAuthorized = settings.authorizationStatus == .authorized ||
                settings.authorizationStatus == .provisional
        }

        guard isAuthorized else {
            throw ExpirationReminderSchedulerError.notificationsNotAuthorized
        }

        let calendar = Calendar.current
        let reminderDate = try ExpirationReminderCalculator.reminderDate(
            for: details.expirationDate,
            daysBefore: details.daysBefore,
            calendar: calendar
        )
        let identifier = UUID().uuidString

        let content = UNMutableNotificationContent()
        content.title = "\(details.itemName) expires soon!"
        content.subtitle =
            "Expiration Date \(details.expirationDate.formatted(date: .abbreviated, time: .omitted))"
        content.sound = .default

        let dateComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
        return identifier
    }
}
