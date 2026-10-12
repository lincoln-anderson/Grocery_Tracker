//
//  AddItemValidatorTests.swift
//  Grocery TrackerTests
//

import Foundation
import Testing

@testable import Grocery_Tracker

struct AddItemValidatorTests {
    @Test
    func `Whitespace-only name is rejected`() {
        #expect(throws: AddItemValidationError.blankName) {
            try AddItemValidator.validatedName(
                "   \n  ",
                purchaseDate: .now,
                expirationDate: .now
            )
        }
    }

    @Test
    func `Expiration before purchase is rejected`() throws {
        let calendar = Calendar(identifier: .gregorian)
        let purchaseDate = try #require(
            calendar.date(from: DateComponents(year: 2027, month: 5, day: 10))
        )
        let expirationDate = try #require(
            calendar.date(from: DateComponents(year: 2027, month: 5, day: 9))
        )

        #expect(throws: AddItemValidationError.expirationBeforePurchase) {
            try AddItemValidator.validatedName(
                "Milk",
                purchaseDate: purchaseDate,
                expirationDate: expirationDate,
                calendar: calendar
            )
        }
    }

    @Test
    func `Same-day expiration is accepted`() throws {
        let calendar = Calendar(identifier: .gregorian)
        let purchaseDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2027,
                    month: 5,
                    day: 10,
                    hour: 18
                )
            )
        )
        let expirationDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2027,
                    month: 5,
                    day: 10,
                    hour: 8
                )
            )
        )

        let name = try AddItemValidator.validatedName(
            "Milk",
            purchaseDate: purchaseDate,
            expirationDate: expirationDate,
            calendar: calendar
        )

        #expect(name == "Milk")
    }

    @Test
    func `Name is trimmed before saving`() throws {
        let name = try AddItemValidator.validatedName(
            "  Milk \n",
            purchaseDate: .now,
            expirationDate: .now
        )

        #expect(name == "Milk")
    }
}
