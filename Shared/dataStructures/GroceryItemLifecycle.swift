//
//  GroceryItemLifecycle.swift
//  Grocery Tracker
//

import CoreData
import Foundation

enum GroceryItemLifecycleStatus: String, CaseIterable, Sendable {
    case active
    case used
    case discarded
}

enum GroceryItemLifecycleError: Error, Equatable {
    case invalidPackageCount
}

struct GroceryItemCompletionPlan: Equatable, Sendable {
    let completedPackageCount: Int
    let remainingPackageCount: Int

    var completesEntireItem: Bool {
        remainingPackageCount == 0
    }

    static func make(
        availablePackageCount: Int,
        completing requestedPackageCount: Int
    ) throws -> GroceryItemCompletionPlan {
        guard availablePackageCount > 0,
              requestedPackageCount > 0,
              requestedPackageCount <= availablePackageCount else {
            throw GroceryItemLifecycleError.invalidPackageCount
        }

        return GroceryItemCompletionPlan(
            completedPackageCount: requestedPackageCount,
            remainingPackageCount: availablePackageCount - requestedPackageCount
        )
    }
}

struct GroceryItemCompletionResult {
    let completedItem: GroceryItem
    let activeRemainder: GroceryItem?
    let notificationIdentifierToCancel: String?
}

@MainActor
enum GroceryItemLifecycleService {
    static func complete(
        _ item: GroceryItem,
        as status: GroceryItemLifecycleStatus,
        packageCount: Int,
        completedAt: Date = .now,
        in context: NSManagedObjectContext
    ) throws -> GroceryItemCompletionResult {
        precondition(status != .active)

        let plan = try GroceryItemCompletionPlan.make(
            availablePackageCount: item.packageCount,
            completing: packageCount
        )
        let notificationIdentifierToCancel = plan.completesEntireItem
            ? item.notificationIdentifier
            : nil

        let completedItem: GroceryItem
        let activeRemainder: GroceryItem?

        if plan.completesEntireItem {
            completedItem = item
            activeRemainder = nil
        } else {
            completedItem = copy(item, into: context)
            completedItem.quantity = Int16(plan.completedPackageCount)
            item.quantity = Int16(plan.remainingPackageCount)
            activeRemainder = item
        }

        completedItem.lifecycleStatus = status.rawValue
        completedItem.completedDate = completedAt
        completedItem.notificationIdentifier = nil

        do {
            try context.save()
            GroceryWidgetSnapshotStore.refresh(in: context)
        } catch {
            context.rollback()
            throw error
        }

        return GroceryItemCompletionResult(
            completedItem: completedItem,
            activeRemainder: activeRemainder,
            notificationIdentifierToCancel: notificationIdentifierToCancel
        )
    }

    static func restore(
        _ item: GroceryItem,
        in context: NSManagedObjectContext
    ) throws {
        item.lifecycleStatus = GroceryItemLifecycleStatus.active.rawValue
        item.completedDate = nil
        item.notificationIdentifier = nil

        do {
            try context.save()
            GroceryWidgetSnapshotStore.refresh(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    private static func copy(
        _ item: GroceryItem,
        into context: NSManagedObjectContext
    ) -> GroceryItem {
        let copy = GroceryItem(context: context)
        copy.barcode = item.barcode
        copy.brand = item.brand
        copy.expirationDate = item.expirationDate
        copy.imageURL = item.imageURL
        copy.measurement = item.measurement
        copy.name = item.name
        copy.packageSize = item.packageSize
        copy.purchasedDate = item.purchasedDate
        copy.quantity = item.quantity
        copy.reminderDaysBefore = item.reminderDaysBefore
        copy.remindersEnabled = item.remindersEnabled
        return copy
    }
}

extension GroceryItem {
    var lifecycleState: GroceryItemLifecycleStatus {
        get {
            lifecycleStatus.flatMap(GroceryItemLifecycleStatus.init(rawValue:))
                ?? .active
        }
        set {
            lifecycleStatus = newValue.rawValue
        }
    }

    var isActive: Bool {
        lifecycleState == .active
    }
}
