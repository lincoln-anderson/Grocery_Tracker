//
//  AddItemView.swift
//  Grocery_Tracker
//
//  Created by lincoln anderson on 4/28/21.
//

import SwiftUI

struct AddItemView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var isPresented: Bool
    
    @State var newName: String = ""
    
    @State var expirationDate: Date
    
    @State var purchaseDate: Date
    
    @State var sendNotification: Bool = true
    
    @State var notificationTime: Int = 3
    
    var containerHeight:CGFloat = UIScreen.main.bounds.height
    
    static let DateFormat: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMM d"
            return formatter
        }()
    
    var body: some View {
        VStack{
            
            Spacer()
            VStack(spacing: 20){
                Text("New Grocery Item")
                    .font(.largeTitle)
                    .bold()
                    .padding(.vertical)
                
                TextField("New Item Name", text: $newName)
                    .padding(.horizontal)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Spacer()
                
                DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    .padding(.horizontal)
                    .font(.largeTitle)
                    .minimumScaleFactor(0.2)
                
                DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                    .padding(.horizontal)
                    .font(.largeTitle)
                    .minimumScaleFactor(0.2)
                if #available(iOS 15.0, *) {
                    Toggle("Expiration Notication", isOn: $sendNotification)
                        .padding(.horizontal)
                        .font(.largeTitle)
                        .minimumScaleFactor(0.2)
                        .tint(colorScheme == .dark ? .white : .black)
                } else {
                    // Fallback on earlier versions
                }
                Text("Choose number of days before expiration notification is sent")
                    .font(.title2)
                    .minimumScaleFactor(0.2)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
                Picker("days before exipring to get notification", selection: $notificationTime, content: {
                    Text("1").tag(1)
                    Text("2").tag(2)
                    Text("3").tag(3)
                    Text("4").tag(4)
                    Text("5").tag(5)
                }).pickerStyle(.segmented)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .font(.title)
                .padding(.horizontal)
                Spacer()
                Button(action: {
                    
                    if sendNotification == true {
                    
                        let content = UNMutableNotificationContent()
                        content.title = "\(newName) expires soon!"
                        
                        let formattedDate = AddItemView.DateFormat.string(from: self.expirationDate)
                        content.subtitle = "Expiration Date \(formattedDate)";
                        content.sound = UNNotificationSound.default
                        
                        var dateComponents = DateComponents()
                        
                        dateComponents.hour = 8
                        
                        dateComponents.minute = 00
                        
                        let newDateFormatter = DateFormatter()
                        newDateFormatter.dateFormat = "MM"
                        
                        dateComponents.month = Int(newDateFormatter.string(from: expirationDate))
                        
                        newDateFormatter.dateFormat = "yyyy"
                        
                        dateComponents.year = Int(newDateFormatter.string(from: expirationDate))
                        
                        newDateFormatter.dateFormat = "dd"
                        
                        dateComponents.day = (Int(newDateFormatter.string(from: expirationDate)) ?? 0) - notificationTime

                        // show this notification five seconds from now
                        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

                        // choose a random identifier
                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                        // add our notification request
                        UNUserNotificationCenter.current().add(request)
                        newItem(newName: newName, expirationDate: expirationDate, purchaseDate: purchaseDate)
                        self.isPresented = false
                        
                    } else {
                        newItem(newName: newName, expirationDate: expirationDate, purchaseDate: purchaseDate)
                        self.isPresented = false
                    }
                    
                }, label: {
                    Text("Save Item")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(colorScheme == .dark ? .white : .black, lineWidth: 5)
                                
                        )

                })
                
                
            }
            
            if containerHeight < 1000 {
                Spacer()
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
        Group {
            AddItemView(isPresented: $isShowing, newName: newName, expirationDate: date, purchaseDate: date)
                .preferredColorScheme(.dark)
            AddItemView(isPresented: $isShowing, newName: newName, expirationDate: date, purchaseDate: date)
                .preferredColorScheme(.light)
        }
    }
}
