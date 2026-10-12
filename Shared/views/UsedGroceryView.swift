//  UsedGroceryView.swift
//  Grocery_Tracker

import SwiftUI
import CoreData

struct UsedGroceryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GroceryItem.expirationDate, ascending: true)],
        animation: .default)
    private var groceryItems: FetchedResults<GroceryItem>
    
    @Binding var isPresented: Bool
    @Binding var filterString: String
    @State private var persistenceError: (any Error)?
    
    var body: some View {
        VStack {
            Text("Swipe left to delete")
                .font(.subheadline)
                .foregroundStyle(Color.sproutGreen)
                .padding(.horizontal)
                .padding(.top, 4)
            List {
                ForEach(groceryItems) { item in
                    GroceryItemCard(item: item)
                        .padding(.vertical, 8) // Increased vertical spacing between items
                        .swipeActions {
                            Button(role: .destructive) {
                                delete(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .accessibilityAction(named: "Delete") {
                            delete(item)
                        }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        }
        .alert("Couldn’t Delete Item", item: $persistenceError) { _ in
            Button("OK", role: .cancel) {}
        } message: { _ in
            Text("The item couldn’t be deleted. Please try again.")
        }
    }
    
    private func delete(_ item: GroceryItem) {
        withAnimation {
            viewContext.delete(item)

            do {
                try viewContext.save()
            } catch {
                viewContext.rollback()
                persistenceError = error
            }
        }
    }
}

struct GroceryItemCard: View {
    let item: GroceryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name?.capitalized ?? "Unnamed")
                    .font(.headline)
                Spacer()
                Text(item.inventorySummary)
                    .font(.subheadline)
                    .foregroundStyle(Color.sproutGreen)
            }
            
            Text("Exp. Date \(item.expirationDate?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                .font(.footnote)
                .foregroundStyle(Color.sproutGreen)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Used Groceries") {
    @Previewable @State var isShowing = true
    @Previewable @State var filterString = ""

    UsedGroceryView(
        isPresented: $isShowing,
        filterString: $filterString
    )
    .environment(
        \.managedObjectContext,
        PersistenceController.preview.container.viewContext
    )
}
