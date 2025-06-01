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
    
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .onChange(of: scenePhase) { _ in
            persistenceController.save()
        }
    }
}
