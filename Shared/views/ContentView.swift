//
//  ContentView.swift
//  Shared
//
//  Created by lincoln anderson on 4/27/21.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GroceryItem.purchasedDate, ascending: true)],
        animation: .default)
    private var groceryItems: FetchedResults<GroceryItem>
    
    @State var showingAddSheet = false

    var body: some View {
        VStack{
            List {
                ForEach(groceryItems) { groceryItem in
                    GroceryItemView(passedGroceryItemName: groceryItem.name!, passedGroceryItemPurchasedDate: groceryItem.purchasedDate!, passedGroceryItemExpirationDate: groceryItem.expirationDate!)
                }
                .onDelete(perform: deleteItems)
            }
            Button(action: {self.showingAddSheet.toggle()}, label: {
                Text("Add Item")
            })
            .sheet(isPresented: $showingAddSheet, onDismiss: {
                
                showingAddSheet = false
                
            }) {
                
                AddItemView(isPresented: $showingAddSheet, newName:"Item Name", expirationDate: Date())
                
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = GroceryItem(context: viewContext)
            newItem.purchasedDate = Date()
            newItem.expirationDate = Date()
            newItem.name = "Sample"

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { groceryItems[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let groceryItemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
