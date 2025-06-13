//
//  ItemDetailView.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 6/13/25.
//

import SwiftUI

struct ItemDetailView: View {
    
    @Environment(\.colorScheme) var colorScheme

    var item: GroceryItem
    
    var body: some View {
        Text(item.displayName)
    }
}
