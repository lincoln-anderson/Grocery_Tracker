//
//  Grocery_TrackerTests.swift
//  Grocery TrackerTests
//

import Foundation
import Testing

@testable import Grocery_Tracker

struct ExpirationReminderCalculatorTests {
    @Test
    func `Reminder crosses into previous month`() throws {
        let calendar = makeCalendar()
        let expirationDate = try makeDate(
            year: 2027,
            month: 2,
            day: 2,
            calendar: calendar
        )
        let now = try makeDate(
            year: 2027,
            month: 1,
            day: 1,
            calendar: calendar
        )

        let reminderDate = try ExpirationReminderCalculator.reminderDate(
            for: expirationDate,
            daysBefore: 3,
            now: now,
            calendar: calendar
        )

        expect(
            reminderDate,
            equals: DateComponents(
                year: 2027,
                month: 1,
                day: 30,
                hour: 8,
                minute: 0
            ),
            calendar: calendar
        )
    }

    @Test
    func `Reminder crosses into previous year`() throws {
        let calendar = makeCalendar()
        let expirationDate = try makeDate(
            year: 2027,
            month: 1,
            day: 2,
            calendar: calendar
        )
        let now = try makeDate(
            year: 2026,
            month: 12,
            day: 1,
            calendar: calendar
        )

        let reminderDate = try ExpirationReminderCalculator.reminderDate(
            for: expirationDate,
            daysBefore: 3,
            now: now,
            calendar: calendar
        )

        expect(
            reminderDate,
            equals: DateComponents(
                year: 2026,
                month: 12,
                day: 30,
                hour: 8,
                minute: 0
            ),
            calendar: calendar
        )
    }

    @Test
    func `Reminder remains at eight AM across daylight saving time`() throws {
        let calendar = makeCalendar(
            timeZoneIdentifier: "America/Indiana/Indianapolis"
        )
        let expirationDate = try makeDate(
            year: 2027,
            month: 3,
            day: 15,
            calendar: calendar
        )
        let now = try makeDate(
            year: 2027,
            month: 3,
            day: 1,
            calendar: calendar
        )

        let reminderDate = try ExpirationReminderCalculator.reminderDate(
            for: expirationDate,
            daysBefore: 1,
            now: now,
            calendar: calendar
        )

        expect(
            reminderDate,
            equals: DateComponents(
                year: 2027,
                month: 3,
                day: 14,
                hour: 8,
                minute: 0
            ),
            calendar: calendar
        )
    }

    @Test
    func `Past reminder is rejected`() throws {
        let calendar = makeCalendar()
        let expirationDate = try makeDate(
            year: 2027,
            month: 1,
            day: 10,
            calendar: calendar
        )
        let now = try makeDate(
            year: 2027,
            month: 1,
            day: 9,
            hour: 9,
            calendar: calendar
        )

        #expect(throws: ExpirationReminderError.reminderNotInFuture) {
            try ExpirationReminderCalculator.reminderDate(
                for: expirationDate,
                daysBefore: 1,
                now: now,
                calendar: calendar
            )
        }
    }

    @Test
    func `Negative reminder interval is rejected`() throws {
        let calendar = makeCalendar()
        let expirationDate = try makeDate(
            year: 2027,
            month: 1,
            day: 10,
            calendar: calendar
        )
        let now = try makeDate(
            year: 2027,
            month: 1,
            day: 1,
            calendar: calendar
        )

        #expect(throws: ExpirationReminderError.invalidDate) {
            try ExpirationReminderCalculator.reminderDate(
                for: expirationDate,
                daysBefore: -1,
                now: now,
                calendar: calendar
            )
        }
    }

    private func makeCalendar(
        timeZoneIdentifier: String = "UTC"
    ) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        return calendar
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        calendar: Calendar
    ) throws -> Date {
        try #require(
            calendar.date(
                from: DateComponents(
                    year: year,
                    month: month,
                    day: day,
                    hour: hour
                )
            )
        )
    }

    private func expect(
        _ date: Date,
        equals expectedComponents: DateComponents,
        calendar: Calendar
    ) {
        let actualComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )

        #expect(actualComponents.year == expectedComponents.year)
        #expect(actualComponents.month == expectedComponents.month)
        #expect(actualComponents.day == expectedComponents.day)
        #expect(actualComponents.hour == expectedComponents.hour)
        #expect(actualComponents.minute == expectedComponents.minute)
    }
}
