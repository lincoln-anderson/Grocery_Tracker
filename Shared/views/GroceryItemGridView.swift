//
//  GroceryItemGridView.swift
//  Grocery_Tracker
//
//  Created by lincoln anderson on 5/4/21.
//

import SwiftUI

struct GroceryItemGridView: View {
    
    var passedGroceryItemName: String
    
    var passedGroceryItemPurchasedDate: Date
    
    var passedGroceryItemExpirationDate: Date
    
    static let DateFormat: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter
        }()
    var body: some View {
        ScrollView{
            Text(passedGroceryItemName)
                .font(.title3)
                .bold()
            Spacer()
            VStack{
                Text("Purchased Date:")
                Text(self.passedGroceryItemPurchasedDate, formatter: GroceryItemGridView.DateFormat)
                Spacer()
                Text("Expiration Date:")
                Text(self.passedGroceryItemExpirationDate, formatter: GroceryItemGridView.DateFormat)
            }
        }
        .frame(minWidth: 150, idealWidth: 150, maxWidth: 150, minHeight: 150, idealHeight: 150, maxHeight: 150, alignment: .center)
        
    }
}

struct GroceryItemGridView_Previews: PreviewProvider {
    
    static var viewContext = PersistenceController.preview.container.viewContext
    
    static var previews: some View {
        let item = GroceryItem(context: viewContext)
        item.expirationDate = Date()
        item.purchasedDate = Date()
        item.name = "Sample"
        
        return GroceryItemGridView(passedGroceryItemName: item.name!, passedGroceryItemPurchasedDate: item.purchasedDate!, passedGroceryItemExpirationDate: item.expirationDate!).environment(\.managedObjectContext, viewContext)
    }
}
