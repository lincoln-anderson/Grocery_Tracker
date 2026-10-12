//
//  MainTabView.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 6/1/25.
//
import SwiftUI

struct MainTabView: View {
    var body: some View {
        SproutsHeader()
        TabView {
            Tab("Tracker", systemImage: "leaf") {
                GroceryItemGrid()
            }

            Tab("Profile", systemImage: "person") {
                ProfileView()
            }
        }
        .tint(.sproutGreen)
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
