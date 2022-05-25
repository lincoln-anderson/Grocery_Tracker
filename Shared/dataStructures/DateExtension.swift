//
//  DateExtension.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 5/25/22.
//

import Foundation

extension Date {
    func isInSevenDays() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.dateComponents([.weekday], from: now)
        let startDate = calendar.startOfDay(for: now)
        let nextWeekday = calendar.nextDate(after: now, matching: weekday, matchingPolicy: .nextTime)!
        let endDate = calendar.date(byAdding: .day, value: 1, to: nextWeekday)!
        return self >= startDate && self < endDate
    }
}
