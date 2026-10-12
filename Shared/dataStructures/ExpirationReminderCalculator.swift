//
//  ExpirationReminderCalculator.swift
//  Grocery Tracker
//

import Foundation

enum ExpirationReminderError: Error, Equatable {
    case invalidDate
    case reminderNotInFuture
}

struct ExpirationReminderCalculator {
    static func reminderDate(
        for expirationDate: Date,
        daysBefore: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) throws -> Date {
        guard daysBefore >= 0,
              let reminderDay = calendar.date(
                byAdding: .day,
                value: -daysBefore,
                to: expirationDate
              ),
              let reminderDate = calendar.date(
                bySettingHour: 8,
                minute: 0,
                second: 0,
                of: reminderDay
              ) else {
            throw ExpirationReminderError.invalidDate
        }

        guard reminderDate > now else {
            throw ExpirationReminderError.reminderNotInFuture
        }

        return reminderDate
    }
}
