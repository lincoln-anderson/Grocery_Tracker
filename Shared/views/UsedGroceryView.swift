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
    
    var body: some View {
        VStack() {
            Text("Swipe left to delete")
                .font(.subheadline)
                .foregroundColor(.sproutGreen)
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
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        }
    }
    
    private func delete(_ item: GroceryItem) {
        withAnimation {
            viewContext.delete(item)
            do {
                try viewContext.save()
            } catch {
                print("Core Data save error: \(error.localizedDescription)")
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
                Text("\(item.quantity) \(item.measurement ?? "")")
                    .font(.subheadline)
                    .foregroundColor(.sproutGreen)
            }
            
            Text("Exp. Date \(item.expirationDate?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                .font(.footnote)
                .foregroundColor(.sproutGreen)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct UsedGroceryView_Previews: PreviewProvider {
    @State static var isShowing = false
    @State static var testString = ""
    
    static var previews: some View {
        UsedGroceryView(isPresented: $isShowing, filterString: $testString)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
