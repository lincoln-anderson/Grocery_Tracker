import Foundation
import Swift

func isToday(date: Date) -> Bool {
    let diff = Calendar.current.isDateInToday(date)
    
    return diff
    
}

func isTomorrow(date: Date) -> Bool {
    let diff = Calendar.current.isDateInTomorrow(date)
    
    return diff
    
}

func getExpired(expiredDate: Date) -> Bool {
    var diff = !isSameDay(date1: expiredDate, date2: Date())
    
    diff = expiredDate < Date()
    
    return diff
}

func isSameDay(date1: Date, date2: Date) -> Bool {
    let diff = Calendar.current.isDate(date1, equalTo: date2, toGranularity: .day)
    
    return diff
        
}

func getWithinWeek(expirationDate: Date) -> Bool {
    var diff = isToday(date: expirationDate)
    
    if diff {
        return false
    }
    let currentDate = Date().addingTimeInterval(86400)
    let outerRange = Date().addingTimeInterval(604800)
    
    let range = currentDate...outerRange
    
    if range.contains(expirationDate) {
        return true
    }
    return diff
}

func getNotWithinWeek(expirationDate: Date) -> Bool {
    let currentDate = Date().addingTimeInterval(86400)
    let outerRange = Date().addingTimeInterval(604800)
    
    let range = currentDate...outerRange
    
    var diff = isToday(date: expirationDate)
    
    if diff {
        return false
    }
    
    diff = getExpired(expiredDate: expirationDate)
    
    if diff {
        return false
    }
    
    if range.contains(expirationDate) {
        return false
    }
    
    return true
}

var dateComponents = DateComponents()
dateComponents.year = 2023
dateComponents.month = 2
dateComponents.day = 28
dateComponents.timeZone = TimeZone(abbreviation: "CST") // Central Standard Time
dateComponents.hour = 23
dateComponents.minute = 00

let userCalendar = Calendar(identifier: .gregorian)
let someDateTime = userCalendar.date(from: dateComponents)
print("is expired:")
print(getExpired(expiredDate: someDateTime!))
print("expires today:")
print(isSameDay(date1: someDateTime!, date2: Date()))
print("expires this week:")
print(getWithinWeek(expirationDate: someDateTime!))
print("expires after this wee:")
print(getNotWithinWeek(expirationDate: someDateTime!))
