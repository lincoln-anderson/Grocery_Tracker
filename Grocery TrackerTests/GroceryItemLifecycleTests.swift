//
//  GroceryItemLifecycleTests.swift
//  Grocery TrackerTests
//

import Testing

@testable import Grocery_Tracker

struct GroceryItemLifecycleTests {
    @Test
    func `Completing some packages leaves an active remainder`() throws {
        let plan = try GroceryItemCompletionPlan.make(
            availablePackageCount: 4,
            completing: 2
        )

        #expect(plan.completedPackageCount == 2)
        #expect(plan.remainingPackageCount == 2)
        #expect(!plan.completesEntireItem)
    }

    @Test
    func `Completing every package completes the entire item`() throws {
        let plan = try GroceryItemCompletionPlan.make(
            availablePackageCount: 3,
            completing: 3
        )

        #expect(plan.completedPackageCount == 3)
        #expect(plan.remainingPackageCount == 0)
        #expect(plan.completesEntireItem)
    }

    @Test(arguments: [
        (available: 3, requested: 0),
        (available: 3, requested: 4),
        (available: 0, requested: 1),
        (available: 3, requested: -1)
    ])
    func `Invalid completion quantities are rejected`(
        available: Int,
        requested: Int
    ) {
        #expect(throws: GroceryItemLifecycleError.invalidPackageCount) {
            try GroceryItemCompletionPlan.make(
                availablePackageCount: available,
                completing: requested
            )
        }
    }
}
