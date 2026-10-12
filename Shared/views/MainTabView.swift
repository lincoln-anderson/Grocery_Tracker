//
//  MainTabView.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 6/1/25.
//
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Groceries", systemImage: "leaf") {
                NavigationStack {
                    GroceryItemGrid()
                }
            }

            Tab("History", systemImage: "clock.arrow.circlepath") {
                NavigationStack {
                    HistoryView()
                }
            }
        }
        .tint(.sproutGreen)
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
