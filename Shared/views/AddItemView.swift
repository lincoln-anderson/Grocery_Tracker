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
    
    @State var newName: String = ""
    
    @State var expirationDate: Date
    
    @State var purchaseDate: Date
    
    static let DateFormat: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            return formatter
        }()
    
    var body: some View {
        VStack{
            
            Spacer()
            Text("New Grocery Item")
                .font(.largeTitle)
            
            
            VStack{
            
                TextField("New Item Name", text: $newName)
                    .padding(.horizontal)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Spacer()
                
                DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    .padding(.horizontal)
                
                Spacer()
                
                DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                    .padding(.horizontal)
                Spacer()
                Button(action: {
                    
                    let content = UNMutableNotificationContent()
                    content.title = "\(newName) expires soon!"
                    
                    let formattedDate = AddItemView.DateFormat.string(from: self.expirationDate)
                    content.subtitle = "Expiration Date \(formattedDate)";
                    content.sound = UNNotificationSound.default
                    
                    var dateComponents = DateComponents()
                    
                    dateComponents.hour = 11
                    
                    dateComponents.minute = 00
                    
                    let newDateFormatter = DateFormatter()
                    newDateFormatter.dateFormat = "MM"
                    
                    dateComponents.month = Int(newDateFormatter.string(from: expirationDate))
                    
                    newDateFormatter.dateFormat = "yyyy"
                    
                    dateComponents.year = Int(newDateFormatter.string(from: expirationDate))
                    
                    newDateFormatter.dateFormat = "dd"
                    
                    dateComponents.day = Int(newDateFormatter.string(from: expirationDate))

                    // show this notification five seconds from now
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

                    // choose a random identifier
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                    // add our notification request
                    UNUserNotificationCenter.current().add(request)
                    newItem(newName: newName, expirationDate: expirationDate, purchaseDate: purchaseDate)
                    self.isPresented = false
                    
                }, label: {
                    Text("Save Item")
                        .font(.largeTitle)
                })
                
            }
                
        }
    }
    
    func newItem(newName: String, expirationDate: Date, purchaseDate: Date) {
        let newItem = GroceryItem(context: viewContext)
        
        newItem.name = newName
        
        newItem.expirationDate = expirationDate
        
        newItem.purchasedDate = purchaseDate
        
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
    @State static var newName = ""
    @State static var date = Date()
    static var previews: some View {
        AddItemView(isPresented: $isShowing, newName: newName, expirationDate: date, purchaseDate: date)
    }
}
