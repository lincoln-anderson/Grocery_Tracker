//
//  LegacyReminderMigration.swift
//  Grocery Tracker
//

import CoreData
import Foundation
import UserNotifications

@MainActor
enum LegacyReminderMigration {
    private static let migrationKey = "didMigrateTrackedRemindersV1"

    static func runIfNeeded(in context: NSManagedObjectContext) async {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: migrationKey) else { return }

        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let settings = await center.notificationSettings()
        let canSchedule = settings.authorizationStatus == .authorized ||
            settings.authorizationStatus == .provisional

        let request = GroceryItem.fetchRequest()
        request.predicate = NSPredicate(
            format: "lifecycleStatus == nil OR lifecycleStatus == %@",
            GroceryItemLifecycleStatus.active.rawValue
        )

        do {
            let items = try context.fetch(request)
            let calendar = Calendar.current

            for item in items {
                guard let expirationDate = item.expirationDate else { continue }

                item.remindersEnabled = canSchedule
                item.reminderDaysBefore = 3
                item.notificationIdentifier = nil

                guard canSchedule,
                      let reminderDate = try? ExpirationReminderCalculator.reminderDate(
                        for: expirationDate,
                        daysBefore: 3,
                        calendar: calendar
                      ) else {
                    continue
                }

                let identifier = UUID().uuidString
                let content = UNMutableNotificationContent()
                content.title = "\(item.displayName) expires soon!"
                content.subtitle =
                    "Expiration Date \(expirationDate.formatted(date: .abbreviated, time: .omitted))"
                content.sound = .default

                let dateComponents = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: reminderDate
                )
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents,
                    repeats: false
                )
                let notificationRequest = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )

                do {
                    try await center.add(notificationRequest)
                    item.notificationIdentifier = identifier
                } catch {
                    item.notificationIdentifier = nil
                }
            }

            if context.hasChanges {
                try context.save()
            }
            defaults.set(true, forKey: migrationKey)
        } catch {
            context.rollback()
        }
    }
}
