//
//  GroceryItemGridSection.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 6/13/25.
//

import SwiftUI

struct GroceryItemGridSection: View {
    
    var section: GrocerySection

    var body: some View {
        Section(header: SectionHeader(text: section.title, color: section.color)) {
            ForEach(section.items) { item in
                NavigationLink(destination: ItemDetailView(item: item)) {
                    
                    
                    GroceryItemGridCard(item: item)
                }
            }
        }
          
    }
}
