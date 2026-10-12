//
//  GroceryItemGridSection.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 6/13/25.
//

import SwiftUI

struct GroceryItemGridSection: View {
    let section: GrocerySection
    let cardStyle: GroceryItemCardStyle
    let onComplete: (GroceryItem, GroceryItemLifecycleStatus) -> Void

    var body: some View {
        Section(header: SectionHeader(text: section.title, color: section.color)) {
            ForEach(section.items) { item in
                NavigationLink(destination: ItemDetailView(item: item)) {
                    GroceryItemGridCard(item: item, style: cardStyle)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        onComplete(item, .discarded)
                    } label: {
                        Label("Discard", systemImage: "trash")
                    }
                    .tint(.orange)

                    Button {
                        onComplete(item, .used)
                    } label: {
                        Label("Used", systemImage: "checkmark")
                    }
                    .tint(.sproutGreen)
                }
                .accessibilityAction(named: "Mark Used") {
                    onComplete(item, .used)
                }
                .accessibilityAction(named: "Discard") {
                    onComplete(item, .discarded)
                }
            }
        }
    }
}
