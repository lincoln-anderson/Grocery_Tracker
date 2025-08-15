//
//  Profile.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 6/1/25.
//
import SwiftUI


struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GroceryItem.expirationDate, ascending: true)],
        animation: .default)
    private var groceryItems: FetchedResults<GroceryItem>
    
    @State var showingRemoveSheet = false
    @State var testString = ""
    
    
    var body: some View {
        let expired = groceryItems.filter { $0.expirationDate?.isExpired == true }
        
        HStack {
            Text("you have \(expired.count) expired items. Would you like to mark them as uses or thrown out?").foregroundColor(.sproutGreen)
            Button("Mark as Used") {
                showingRemoveSheet = true
            }
            .buttonStyle(SproutsButtonStyle(color: .green))
            .sheet(isPresented: $showingRemoveSheet) {
                UsedGroceryView(
                    isPresented: $showingRemoveSheet,
                    filterString: $testString
                )
                .environment(\.managedObjectContext, viewContext)
            }
            
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
