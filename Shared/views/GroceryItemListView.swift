//
//  GroceryItemView.swift
//  Grocery_Tracker
//
//  Created by lincoln anderson on 4/27/21.
//

import SwiftUI

struct GroceryItemListView: View {
    let passedGroceryItemName: String
    let passedGroceryItemPurchasedDate: Date
    let passedGroceryItemExpirationDate: Date
    let passedGroceryItemQuantity: Int16
    let passedGroceryItemMeasurement: String

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Text(passedGroceryItemName)
                    .foregroundStyle(.primary)
                    .font(.title.bold())

                Spacer()

                VStack {
                    Text("\(passedGroceryItemQuantity) \(passedGroceryItemMeasurement)")
                        .bold()
                    Text(
                        "Exp. Date \(passedGroceryItemExpirationDate.formatted(date: .abbreviated, time: .omitted))"
                    )
                    .bold()
                }
            }
        }
    }
}

#Preview("Grocery Item List Row") {
    GroceryItemListView(
        passedGroceryItemName: "Sample",
        passedGroceryItemPurchasedDate: .now,
        passedGroceryItemExpirationDate: .now,
        passedGroceryItemQuantity: 10,
        passedGroceryItemMeasurement: "Oz"
    )
    .padding()
}
