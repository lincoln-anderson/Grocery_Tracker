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
            formatter.dateFormat = "E, MMM d"
            return formatter
            }()
    
    var body: some View {
        VStack{
            Spacer()
            HStack{
                Text(passedGroceryItemName)
                    .font(.title)
                    .bold()
                Spacer()
                VStack{
                    Text("Exp. Date \(self.passedGroceryItemExpirationDate, formatter: GroceryItemListView.DateFormat)")
                        .bold()
                }
            }
        }
    }
}

struct GroceryItemListView_Previews: PreviewProvider {
    
    static var viewContext = PersistenceController.preview.container.viewContext
    
    static var previews: some View {
        let item = GroceryItem(context: viewContext)
        item.expirationDate = Date()
        item.name = "Sample"
        
        return GroceryItemListView(passedGroceryItemName: item.name!, passedGroceryItemPurchasedDate: item.purchasedDate!, passedGroceryItemExpirationDate: item.expirationDate!).environment(\.managedObjectContext, viewContext)
    }
}
