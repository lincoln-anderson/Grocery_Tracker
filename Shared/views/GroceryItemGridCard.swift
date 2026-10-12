//  GroceryItemGridView.swift
//  Grocery_Tracker

import SwiftUI

struct GroceryItemGridCard: View {
    let item: GroceryItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.headline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 52, alignment: .leading)

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.sproutGreen)
                        .accessibilityHidden(true)
                    Text(item.expirationDate?.shortDisplayString ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "scalemass")
                        .foregroundStyle(Color.sproutGreen)
                        .accessibilityHidden(true)
                    Text(item.inventorySummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Grocery Item Card") {
    let context = PersistenceController.preview.container.viewContext
    let item = GroceryItem(context: context)
    item.expirationDate = .now
    item.name = "Canned Beans"
    item.quantity = 2
    item.packageSize = "15 oz"

    return GroceryItemGridCard(item: item)
        .environment(\.managedObjectContext, context)
        .padding(.vertical)
}
