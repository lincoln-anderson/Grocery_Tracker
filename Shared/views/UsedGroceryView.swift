//
//  UsedGroceryView.swift
//  Grocery_Tracker
//
//  Created by lincoln anderson on 5/3/21.
//

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
        VStack{
            if #available(iOS 15.0, *) {
                List() {
                    Section(header: myHeader()) {
                        ForEach(groceryItems) { groceryItem in
                            GroceryItemListView(passedGroceryItemName: groceryItem.name!, passedGroceryItemPurchasedDate: groceryItem.purchasedDate!, passedGroceryItemExpirationDate: groceryItem.expirationDate!)
                        }
                    
                    .onDelete(perform: deleteItems)
                    }
                }.environment(\.defaultMinListRowHeight, 100)
                    
            } else {
                // Fallback on earlier versions
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

struct UsedGroceryView_Previews: PreviewProvider {
    @State static var isShowing = false
    
    
    @State static var testString = "string"
    
    static var previews: some View {
        UsedGroceryView(isPresented: $isShowing, filterString: $testString)
    }
}

struct myHeader: View {
    var body: some View {
        HStack {
            Text("Swipe left to delete")
        }
    }
}
