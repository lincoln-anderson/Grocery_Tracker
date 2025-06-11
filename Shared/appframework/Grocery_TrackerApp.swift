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
    
    init() {
            UIView.appearance().overrideUserInterfaceStyle = .light
        }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

