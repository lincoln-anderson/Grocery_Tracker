//
//  GroceryWidgetSnapshotStore.swift
//  Grocery Tracker
//

import CoreData
import Foundation
import WidgetKit

struct GroceryWidgetItem: Codable, Sendable {
    let id: String
    let name: String
    let inventorySummary: String
    let expirationDate: Date
}

@MainActor
enum GroceryWidgetSnapshotStore {
    static let appGroupIdentifier = "group.SproutsGroceryTracker"
    static let snapshotKey = "activeGroceryWidgetItems"
    static let widgetKind = "GroceryTrackerWidget"

    static func refresh(in context: NSManagedObjectContext) {
        let request = GroceryItem.fetchRequest()
        request.predicate = NSPredicate(
            format: "lifecycleStatus == nil OR lifecycleStatus == %@",
            GroceryItemLifecycleStatus.active.rawValue
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \GroceryItem.expirationDate, ascending: true)
        ]

        do {
            let items = try context.fetch(request)
                .compactMap { item -> GroceryWidgetItem? in
                    guard let expirationDate = item.expirationDate else { return nil }

                    return GroceryWidgetItem(
                        id: item.objectID.uriRepresentation().absoluteString,
                        name: item.displayName,
                        inventorySummary: item.inventorySummary,
                        expirationDate: expirationDate
                    )
                }
                .prefix(3)
            let data = try JSONEncoder().encode(Array(items))
            UserDefaults(suiteName: appGroupIdentifier)?.set(data, forKey: snapshotKey)
            WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        } catch {
            // The app remains the source of truth if a widget snapshot can’t be refreshed.
        }
    }
}
