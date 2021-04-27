//
//  Grocery_TrackerApp.swift
//  Shared
//
//  Created by lincoln anderson on 4/27/21.
//

import SwiftUI

@main
struct Grocery_TrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
