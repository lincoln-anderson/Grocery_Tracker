//
//  DateExtension.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 5/25/22.
//

import Foundation

extension Date {
    
    /// Checks if the date is the same day as another date
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .day)
    }

    /// Checks if the date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Checks if the date is tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Checks if the date is expired (before today, not today)
    var isExpired: Bool {
        self < Date() && !self.isToday
    }

    /// Checks if the date is within a number of future days
    func isWithin(days: Int) -> Bool {
        let now = Date()
        let future = now.addingTimeInterval(Double(days) * 86400)
        return self > now && self <= future
    }

    /// Returns the number of full days between two dates
    func days(until other: Date) -> Int? {
        Calendar.current.dateComponents([.day], from: self, to: other).day
    }

    /// Shifts a date by a number of days
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Formats the date as "E, MMM d" (e.g., "Mon, May 30")
    var shortDisplayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: self)
    }
}

