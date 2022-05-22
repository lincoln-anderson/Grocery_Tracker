//
//  GroceryItemGridView.swift
//  Grocery_Tracker
//
//  Created by lincoln anderson on 5/4/21.
//

import SwiftUI

struct GroceryItemGridView: View {
    
    var passedGroceryItemName: String
    
    var passedGroceryItemExpirationDate: Date
    
    let interval = Date()
    
    static let DateFormat: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter
        }()
    var body: some View {
        ScrollView{
                VStack{
                    Spacer()
                    VStack{
                        Text(passedGroceryItemName)
                            .font(.body)
                            .bold()
                        Spacer()
                        VStack{
                            Text("Exp. Date:")
                            Spacer()
                            Text(self.passedGroceryItemExpirationDate, formatter: GroceryItemGridView.DateFormat)
                        }
                    }
                    Spacer()
                }
        }
        .frame(minWidth: 150, idealWidth: 150, maxWidth: 150, minHeight: 85, idealHeight: 85, maxHeight: 85, alignment: .center)
        .padding(.all)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue, lineWidth: 4)
        )
        
    }
}

struct GroceryItemGridView_Previews: PreviewProvider {
    
    static var viewContext = PersistenceController.preview.container.viewContext
    
    static var previews: some View {
        let item = GroceryItem(context: viewContext)
        item.expirationDate = Date()
        item.name = "Sample"
        
        return GroceryItemGridView(passedGroceryItemName: item.name!, passedGroceryItemExpirationDate: item.expirationDate!).environment(\.managedObjectContext, viewContext)
    }
}


func computeNewDate(from fromDate: Date, to toDate: Date) -> Date  {
     let delta = toDate.timeIntervalSince(fromDate)
     let today = Date()
     if delta < 0 {
         return today
     } else {
         return today.addingTimeInterval(delta)
     }
}
