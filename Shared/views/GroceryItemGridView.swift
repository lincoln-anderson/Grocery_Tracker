//
//  GroceryItemGridView.swift
//  Grocery_Tracker
//
//  Created by lincoln anderson on 5/4/21.
//

import SwiftUI

struct GroceryItemGridView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var passedGroceryItemName: String
    
    var passedGroceryItemExpirationDate: Date
    
    var containerWidth:CGFloat = UIScreen.main.bounds.width - 32.0
    
    let interval = Date()
    
    static let DateFormat: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMM d"
            return formatter
        }()
    var body: some View {
        if passedGroceryItemExpirationDate >= Date() || isSameDay(date1: interval, date2: passedGroceryItemExpirationDate) {
            VStack{
                VStack(spacing: 10){
                    Text(passedGroceryItemName)
                        .font(.title2)
                        .bold()
                        .frame(width: containerWidth/2.2)
                        .scaledToFill()
                        .minimumScaleFactor(0.4)
                        .multilineTextAlignment(.center)
                    HStack{
                        Text("Exp.")
                            .bold()
                        Spacer()
                        Text(self.passedGroceryItemExpirationDate, formatter: GroceryItemGridView.DateFormat)
                            .bold()
                    }
                }
            }
            .frame(minWidth: containerWidth * 0.42, idealWidth: containerWidth * 0.42, maxWidth: containerWidth * 0.42, minHeight: 85, idealHeight: 85, maxHeight: 85, alignment: .center)
            .padding(.all)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .dark ? .white : .black, lineWidth: 6)
            )
            
        } else {
            VStack{
                Spacer()
                VStack(spacing: 10){
                    Text(passedGroceryItemName)
                        .font(.title2)
                        .bold()
                        .frame(width: containerWidth/2.2)
                        .scaledToFill()
                        .minimumScaleFactor(0.4)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.red)
                    Spacer()
                    HStack{
                        Text("Exp.")
                            .bold()
                            .foregroundColor(.red)

                        Spacer()
                        Text(self.passedGroceryItemExpirationDate, formatter: GroceryItemGridView.DateFormat)
                            .bold()
                            .foregroundColor(.red)
                    }
                }
            }
            .frame(minWidth: 150, idealWidth: 168, maxWidth: 168, minHeight: 85, idealHeight: 85, maxHeight: 85, alignment: .center)
            .padding(.all)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.red, lineWidth: 6)
            )
        }
        
    }
}

struct GroceryItemGridView_Previews: PreviewProvider {
    
    static var viewContext = PersistenceController.preview.container.viewContext
    
    static var previews: some View {
        let item = GroceryItem(context: viewContext)
        item.expirationDate = Date()
        item.name = "Sample Sample"
        
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
