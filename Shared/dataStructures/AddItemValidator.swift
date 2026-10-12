//
//  AddItemValidator.swift
//  Grocery Tracker
//

import Foundation

enum AddItemValidationError: Error, Equatable, Identifiable {
    case blankName
    case expirationBeforePurchase

    var id: Self { self }
}

struct AddItemValidator {
    static func validatedName(
        _ name: String,
        purchaseDate: Date,
        expirationDate: Date,
        calendar: Calendar = .current
    ) throws -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            throw AddItemValidationError.blankName
        }

        guard calendar.startOfDay(for: expirationDate)
            >= calendar.startOfDay(for: purchaseDate) else {
            throw AddItemValidationError.expirationBeforePurchase
        }

        return trimmedName
    }
}
