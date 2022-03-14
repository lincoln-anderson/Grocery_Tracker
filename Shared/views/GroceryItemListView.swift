//
//  GroceryItemView.swift
//  Grocery_Tracker
//
//  Created by lincoln anderson on 4/27/21.
//

import SwiftUI

struct GroceryItemListView: View {
    
    var passedGroceryItemName: String
    
    var passedGroceryItemPurchasedDate: Date
    
    var passedGroceryItemExpirationDate: Date
    
    static let DateFormat: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter
        }()
    
    var body: some View {
        HStack{
            Text(passedGroceryItemName)
                .bold()
            Spacer()
            VStack{
                Text("Purchased Date \(self.passedGroceryItemPurchasedDate, formatter: GroceryItemListView.DateFormat)")
                Spacer()
                Text("Expiration Date \(self.passedGroceryItemExpirationDate, formatter: GroceryItemListView.DateFormat)")
            }
        }
        
    }
}

struct GroceryItemListView_Previews: PreviewProvider {
    
    static var viewContext = PersistenceController.preview.container.viewContext
    
    static var previews: some View {
        let item = GroceryItem(context: viewContext)
        item.expirationDate = Date()
        item.purchasedDate = Date()
        item.name = "Sample"
        
        return GroceryItemListView(passedGroceryItemName: item.name!, passedGroceryItemPurchasedDate: item.purchasedDate!, passedGroceryItemExpirationDate: item.expirationDate!).environment(\.managedObjectContext, viewContext)
    }
}
