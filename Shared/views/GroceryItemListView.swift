//
//  GroceryItemView.swift
//  Grocery_Tracker
//
//  Created by lincoln anderson on 4/27/21.
//

import SwiftUI

struct GroceryItemListView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var passedGroceryItemName: String
    
    var passedGroceryItemPurchasedDate: Date
    
    var passedGroceryItemExpirationDate: Date
    
    var passedGroceryItemQuantity: Int16
    
    var passedGroceryItemMeasurement: String
    
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
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .font(.title)
                    .bold()
                    
                Spacer()
                VStack{
                    HStack{
                        Text(String(self.passedGroceryItemQuantity))
                            .bold()
                        Text(self.passedGroceryItemMeasurement)
                            .bold()
                    }
                    Text("Exp. Date \(self.passedGroceryItemExpirationDate, formatter: GroceryItemListView.DateFormat)")
                        .bold()
                    
                }
            }
        }
    }
}

func isExpired(expirationDate: Date) -> Bool {
    let isExpiredBool = expirationDate <= Date() && !isSameDay(date1: Date(), date2: expirationDate)
    return isExpiredBool
}

struct GroceryItemListView_Previews: PreviewProvider {
    
    static var viewContext = PersistenceController.preview.container.viewContext
    
    static var previews: some View {
        let item = GroceryItem(context: viewContext)
        item.expirationDate = Date()
        item.name = "Sample"
        item.quantity = 10
        item.measurement = "Oz"
        
        return GroceryItemListView(passedGroceryItemName: item.name!, passedGroceryItemPurchasedDate: item.purchasedDate!, passedGroceryItemExpirationDate: item.expirationDate!, passedGroceryItemQuantity: item.quantity, passedGroceryItemMeasurement: item.measurement!).environment(\.managedObjectContext, viewContext)
    }
}
