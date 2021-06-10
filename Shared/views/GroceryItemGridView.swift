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
    
    static let DateFormat: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter
        }()
    var body: some View {
        ScrollView{
            VStack{
                Spacer()
                HStack{
                    Text(passedGroceryItemName)
                        .font(.body)
                        .bold()
                    VStack{
                        Text("Exp. Date:")
                        Text(self.passedGroceryItemExpirationDate, formatter: GroceryItemGridView.DateFormat)
                    }
                }
                Spacer()
            }
        }
        .frame(minWidth: 150, idealWidth: 150, maxWidth: 150, minHeight: 75, idealHeight: 75, maxHeight: 75, alignment: .center)
        .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue, lineWidth: 4)
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
