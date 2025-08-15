//
//  AddItemView.swift
//  Grocery_Tracker
//
//  Created by lincoln anderson on 4/28/21.
//

import SwiftUI

private let AddItemDateFormat: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "E, MMM d"
    return formatter
}()

struct AddItemView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var isPresented: Bool
    
    @State var newName: String = ""
    
    @State var expirationDate: Date
    
    @State var purchaseDate: Date
    
    @State var quantity: String = ""
    
    @State var measurement: String = Measurements.oz.rawValue
    
    @State var sendNotification: Bool = true
    
    @State var notificationTime: Int = 3
    
    enum Measurements: String, CaseIterable, Identifiable {
        
        case oz
        case lb
        case ml
        
        var id: String { self.rawValue }
        
    }
    
    var containerHeight:CGFloat = UIScreen.main.bounds.height
    
    var body: some View {
        VStack{
            
            Spacer()
            VStack(spacing: 20){
                VStack(alignment: .leading, spacing: 12) {
                    Text("New Grocery Item")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.sproutGreen)
                        .padding(.top)
                        .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                }
                
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Item Name")
                        .font(.subheadline)
                        .foregroundColor(.sproutGreen)
                    
                    TextField("Item Name", text: $newName)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                HStack() {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Purchase Date")
                            .font(.subheadline)
                            .foregroundColor(.sproutGreen)
                        
                        DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Expiration Date")
                            .font(.subheadline)
                            .foregroundColor(.sproutGreen)
                        
                        DatePicker("", selection: $expirationDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quantity & Measurement")
                        .font(.subheadline)
                        .foregroundColor(.sproutGreen)
                    
                    HStack {
                        TextField("Item weight", text: $quantity)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .keyboardType(.decimalPad)
                            .onChange(of: quantity) { newValue in
                                let filtered = newValue.filter { "0123456789.".contains($0) }
                                // Only allow one period
                                let parts = filtered.split(separator: ".", omittingEmptySubsequences: false)
                                if parts.count <= 2 {
                                    quantity = parts.joined(separator: ".")
                                } else {
                                    quantity = parts[0] + "." + parts[1]
                                }
                            }

                        Picker("Measurement", selection: $measurement) {
                            ForEach(Measurements.allCases) { Text($0.rawValue.capitalized) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 100)
                }
                .padding(.horizontal)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Expiration Alert")
                        .font(.headline)
                        .padding(.bottom, 2)
                    
                    Toggle("Enable Notification", isOn: $sendNotification)
                        .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.32, green: 0.55, blue: 0.39)))
                    
                    Text("Remind me this many days before expiration:")
                        .font(.subheadline)
                        .foregroundColor(.sproutGreen)
                    
                    Picker("", selection: $notificationTime) {
                        ForEach(1...5, id: \.self) { day in
                            Text("\(day)")
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Button(action: {
                    if sendNotification == true {
                        let content = UNMutableNotificationContent()
                        content.title = "\(newName) expires soon!"
                        
                        let formattedDate = AddItemDateFormat.string(from: self.expirationDate)
                        content.subtitle = "Expiration Date \(formattedDate)"
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
                        
                        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                        UNUserNotificationCenter.current().add(request)
                        
                        newItem(newName: newName, expirationDate: expirationDate, purchaseDate: purchaseDate, quantity: Double(quantity) ?? 1, measurement: measurement)
                        self.isPresented = false
                    } else {
                        newItem(newName: newName, expirationDate: expirationDate, purchaseDate: purchaseDate, quantity: Double(quantity) ?? 1, measurement: measurement)
                        self.isPresented = false
                    }
                }) {
                    Text("Save Item")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.sproutGreen)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                        .padding(.horizontal)
                }
            }
            
            if containerHeight < 1000 {
                Spacer()
            }
            
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    func newItem(newName: String, expirationDate: Date, purchaseDate: Date, quantity: Double, measurement: String) {
        let newItem = GroceryItem(context: viewContext)
        
        newItem.name = newName
        
        newItem.expirationDate = expirationDate
        
        newItem.purchasedDate = purchaseDate
        
        newItem.quantity = quantity
        
        newItem.measurement = measurement
        
        do {
            try viewContext.save()
        } catch {
            print("Core Data save error: \(error.localizedDescription)")
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
    @State static var quantity = "1"
    static var previews: some View {
        Group {
            AddItemView(isPresented: $isShowing, newName: newName, expirationDate: date, purchaseDate: date, quantity: quantity, measurement: newName)
                .preferredColorScheme(.dark)
            AddItemView(isPresented: $isShowing, newName: newName, expirationDate: date, purchaseDate: date, quantity: quantity, measurement: newName)
                .preferredColorScheme(.light)
        }
    }
}

