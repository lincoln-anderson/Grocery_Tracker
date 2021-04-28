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
    
    var body: some View {
        VStack{
            Text("New Grocery Item")
            
            TextField("New Name", text: $newName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
        }
    }
}

struct AddItemView_Previews: PreviewProvider {
    @State static var isShowing = false
    @State static var newName = "Sample"
    static var previews: some View {
        AddItemView(isPresented: $isShowing, newName: newName)
    }
}
