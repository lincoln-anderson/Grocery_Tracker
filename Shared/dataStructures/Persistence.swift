//
//  Persistence.swift
//  Shared
//
//  Created by lincoln anderson on 4/27/21.
//

import CoreData
import Observation
import OSLog

enum PersistentStoreState: Equatable {
    case loading
    case ready
    case failed
}

@MainActor
@Observable
final class PersistenceController {
    static let shared = PersistenceController()

    static let preview = PersistenceController(inMemory: true)

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "GroceryTracker",
        category: "Persistence"
    )

    private let inMemory: Bool

    private(set) var loadState = PersistentStoreState.loading
    private(set) var container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        self.inMemory = inMemory
        self.container = Self.makeContainer(inMemory: inMemory)
        loadPersistentStore()
    }

    func retryLoading() {
        guard loadState == .failed else { return }

        container = Self.makeContainer(inMemory: inMemory)
        loadPersistentStore()
    }

    func save() throws {
        let context = container.viewContext

        if context.hasChanges {
            try context.save()
        }
    }

    private func loadPersistentStore() {
        loadState = .loading

        container.loadPersistentStores { [weak self] _, error in
            guard let self else { return }

            if let error {
                Self.logger.error("Failed to load persistent store: \(error.localizedDescription, privacy: .public)")
                loadState = .failed
            } else {
                loadState = .ready
            }
        }
    }

    private static func makeContainer(inMemory: Bool) -> NSPersistentCloudKitContainer {
        let container = NSPersistentCloudKitContainer(name: "Grocery_Tracker")

        if inMemory,
           let storeDescription = container.persistentStoreDescriptions.first {
            storeDescription.url = URL(fileURLWithPath: "/dev/null")
        }

        return container
    }
}
