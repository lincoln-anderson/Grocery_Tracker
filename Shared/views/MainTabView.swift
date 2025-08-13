//
//  MainTabView.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 6/1/25.
//
import SwiftUI

struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemGray6

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    var body: some View {
        SproutsHeader()
        TabView {
            GroceryItemGrid()
                .tabItem { Label("Tracker", systemImage: "leaf") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
        }
        .tint(.sproutGreen)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
