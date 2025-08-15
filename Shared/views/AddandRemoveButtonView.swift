//
//  AddandRemoveButtonView.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 6/13/25.
//

import SwiftUI

public struct AddandRemoveButtonView: View {
    
    @Binding var showingAddSheet: Bool
    
    @Binding var showingRemoveSheet: Bool
    
    @Binding var filterText: String
    
    @Environment(\.managedObjectContext) var viewContext
    
    public var body: some View {
        HStack {
            Button("Add Item") {
                showingAddSheet = true
            }
            .buttonStyle(SproutsButtonStyle(color: .green))
            .sheet(isPresented: $showingAddSheet) {
                AddItemView(
                    isPresented: $showingAddSheet,
                    expirationDate: Date(),
                    purchaseDate: Date(),
                    quantity: ""
                )
                .environment(\.managedObjectContext, viewContext)
            }
            
            
            Button("Mark as Used") {
                showingRemoveSheet = true
            }
            .buttonStyle(SproutsButtonStyle(color: .green))
            .sheet(isPresented: $showingRemoveSheet) {
                UsedGroceryView(
                    isPresented: $showingRemoveSheet,
                    filterString: $filterText
                )
                .environment(\.managedObjectContext, viewContext)
            }
            
            
        }
        .padding(.bottom, 8)
    }
}
