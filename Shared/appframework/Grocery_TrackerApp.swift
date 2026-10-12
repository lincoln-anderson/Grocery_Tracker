//
//  Grocery_TrackerApp.swift
//  Shared
//
//  Created by lincoln anderson on 4/27/21.
//

import SwiftUI

@main
struct Grocery_TrackerApp: App {
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            GroceryTrackerRootView(persistenceController: persistenceController)
        }
    }
}

private struct GroceryTrackerRootView: View {
    let persistenceController: PersistenceController

    var body: some View {
        switch persistenceController.loadState {
        case .loading:
            ProgressView("Loading Groceries…")
        case .ready:
            MainTabView()
                .environment(
                    \.managedObjectContext,
                    persistenceController.container.viewContext
                )
        case .failed:
            PersistentStoreRecoveryView(
                retryAction: persistenceController.retryLoading
            )
        }
    }
}

private struct PersistentStoreRecoveryView: View {
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("Grocery Data Unavailable")
                .font(.title2)
                .bold()

            Text("The app couldn’t open your grocery data. Check your available storage, then try again.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Try Again", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
