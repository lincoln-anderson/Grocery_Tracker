//
//  AddItemView.swift
//  Grocery_Tracker
//
//  Created by lincoln anderson on 4/28/21.
//

import SwiftUI

struct AddItemView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var isPresented: Bool
    
    @State var newName: String
    
    @State var expirationDate: Date
    
    var body: some View {
        VStack{
            Text("New Grocery Item")
            
            TextField("New Name", text: $newName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            DatePicker("Experation Date", selection: $expirationDate, displayedComponents: .date)
            Spacer()
            Button(action: {
                newItem(newName: newName, expirationDate: expirationDate)
                self.isPresented = false
                
            }, label: {
                Text("Save Item")
            })
                
        }
    }
    
    func newItem(newName: String, expirationDate: Date) {
        let newItem = GroceryItem(context: viewContext)
        
        newItem.name = newName
        
        newItem.expirationDate = expirationDate
        
        newItem.purchasedDate = Date()
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct AddItemView_Previews: PreviewProvider {
    @State static var isShowing = false
    @State static var newName = "Sample"
    @State static var date = Date()
    static var previews: some View {
        AddItemView(isPresented: $isShowing, newName: newName, expirationDate: date)
    }
}
