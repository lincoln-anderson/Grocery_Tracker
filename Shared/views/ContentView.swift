//
//  ContentView.swift
//  Shared
//
//  Created by lincoln anderson on 4/27/21.
//

import SwiftUI
import CoreData
import UserNotifications

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GroceryItem.expirationDate, ascending: true)],
        animation: .default)
    private var groceryItems: FetchedResults<GroceryItem>
    
    @State var showingAddSheet = false
    
    @State var showingRemoveSheet = false
    
    @State var showingEditSheet = false
    
    @State var showingAlert = false
    
    @State var testString = "string"
    
    var containerWidth:CGFloat = UIScreen.main.bounds.width - 32.0
    
    var containerHeight:CGFloat = UIScreen.main.bounds.height
    

    let columns = [
        GridItem(.adaptive(minimum: 180))
    ]

    var body: some View {
        
        VStack{
            ScrollView {
                if groceryItems.count == 0 {
                    Text("Tap the \"Add Item\" button to add your groceries and begin tracking the expiration dates").bold()
                        .font(.title)
                        .multilineTextAlignment(.center)
                }
                LazyVGrid(columns: columns, spacing: 15, pinnedViews: .sectionHeaders) {
                    // MARK: is expired
                    if getExpired(groceryItems: groceryItems).count > 0 {
                        if getExpired(groceryItems: groceryItems).count == 1 {
                            Section(header:
                                        Text("This \(getExpired(groceryItems: groceryItems).count) item has expired!").bold()
                                .font(.title)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)

                            ) {
                                    ForEach(getExpired(groceryItems: groceryItems)) { groceryItem in
                                        GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!, passedGroceryQuantity: groceryItem.quantity, passedMeasurement: groceryItem.measurement!)
                                    }.onTapGesture {
                                        let _ = print("tapped")
                                    }
                            }
                        } else {
                            Section(header:
                                        Text("These \(getExpired(groceryItems: groceryItems).count) items have expired!").bold()
                                .font(.title)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)

                            ) {
                                ForEach(getExpired(groceryItems: groceryItems)) { groceryItem in
                                    GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!, passedGroceryQuantity: groceryItem.quantity, passedMeasurement: groceryItem.measurement!)
                                }
                            }
                        }
                    }
                    // MARK: expires today section
                    if isToday(groceryItems: groceryItems).count > 0 {
                        if isToday(groceryItems: groceryItems).count == 1 {
                            Section(header:
                                        Text("This 1 item expires today").bold()
                                .font(.title)
                                .multilineTextAlignment(.center)
                            ) {
                                ForEach(isToday(groceryItems: groceryItems)) { groceryItem in
                                    GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!, passedGroceryQuantity: groceryItem.quantity, passedMeasurement: groceryItem.measurement!)
                                }
                            }
                        } else {
                            Section(header:
                                        Text("These \(isToday(groceryItems: groceryItems).count) items expire today").bold()
                                .font(.title)
                                .multilineTextAlignment(.center)
                            ) {
                                ForEach(isToday(groceryItems: groceryItems), id: \.self) { groceryItem in
                                    GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!, passedGroceryQuantity: groceryItem.quantity, passedMeasurement: groceryItem.measurement ?? "")
                                }.onTapGesture {
                                    print("onTap")
                                }
                            }
                        }
                    }
                    
                    // MARK: expires within week section
                    if getWithinWeek(groceryItems: groceryItems).count > 0 {
                        if getWithinWeek(groceryItems: groceryItems).count == 1 {
                            Section(header:
                                        Text("This 1 item will expire within 7 days").bold()
                                .font(.title)
                                .multilineTextAlignment(.center)
                            ) {
                                ForEach(getWithinWeek(groceryItems: groceryItems)) { groceryItem in
                                    GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!, passedGroceryQuantity: groceryItem.quantity, passedMeasurement: groceryItem.measurement!)
                                }
                            }
                        } else {
                            Section(header:
                                        Text("These \(getWithinWeek(groceryItems: groceryItems).count) items will expire within 7 days")
                                .bold()
                                .font(.title)
                                .multilineTextAlignment(.center)
                            ) {
                                ForEach(getWithinWeek(groceryItems: groceryItems)) { groceryItem in
                                    GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!, passedGroceryQuantity: groceryItem.quantity, passedMeasurement: groceryItem.measurement!)
                                }
                            }
                        }
                    }
                    
                    // MARK: expires after 7 days
                    if getNotWithinWeek(groceryItems: groceryItems).count > 0 {
                        if getNotWithinWeek(groceryItems: groceryItems).count == 1 {
                            Section(header:
                                        Text("This \(getNotWithinWeek(groceryItems: groceryItems).count) item will expire in more than 7 days").bold()
                                .font(.title)
                                .multilineTextAlignment(.center)
                            ) {
                                ForEach(getNotWithinWeek(groceryItems: groceryItems)) { groceryItem in
                                    GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!, passedGroceryQuantity: groceryItem.quantity, passedMeasurement: groceryItem.measurement!)
                                }
                            }
                        } else {
                            Section(header:
                                        Text("These \(getNotWithinWeek(groceryItems: groceryItems).count) items expire after more than 7 days").bold()
                                .font(.title)
                                .multilineTextAlignment(.center)
                            ) {
                                ForEach(getNotWithinWeek(groceryItems: groceryItems)) { groceryItem in
                                    GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!, passedGroceryQuantity: groceryItem.quantity, passedMeasurement: groceryItem.measurement!)
                                }
                            }
                        }
                    }
                    
                }
                .onTapGesture {
                    let _ = print("tapped1")
                }
            }
            Spacer()
            // MARK: Buttons
            VStack{
            
                
                
                Button(action: {
                                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                                        if success {
                                            print("All set!")
                                        } else if let error = error {
                                            print(error.localizedDescription)
                                        }
                                    }
                
                                    self.showingAddSheet.toggle()
                
                            }, label: {
                                Text("Add Item")
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .frame(width: containerWidth * 0.95, height: 40)
                                    .padding()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(colorScheme == .dark ? .white : .black, lineWidth: 5)
                                            
                                    )
                            })
                            .sheet(isPresented: $showingAddSheet, onDismiss: {
                
                                showingAddSheet = false
                
                            }) {
                                let _ = print("tapped")

                                AddItemView(isPresented: $showingAddSheet, expirationDate: Date(), purchaseDate: Date(), quantity: 1).environment(\.managedObjectContext, self.viewContext)
                
                            }
                
                Button(action: {self.showingRemoveSheet.toggle()}, label: {
                        Text("Mark Item as Used")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(width: containerWidth * 0.95, height: 40)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(colorScheme == .dark ? .white : .black, lineWidth: 6)
                                
                        )
                    
                })
                    .sheet(isPresented: $showingRemoveSheet, onDismiss: {
        
                        showingAddSheet = false
        
                    }) {
        
                        UsedGroceryView(isPresented: $showingRemoveSheet, filterString: $testString).environment(\.managedObjectContext, self.viewContext)
        
                    }
            
            }
            if containerHeight < 1000 {
                Spacer()
            }
                
        }
    }
    
    // MARK: view methods
    private func deleteItems(offsets: IndexSet) {
        print(offsets.map { groceryItems[$0] })
    }

    private func addItem() {
        withAnimation {
            let newItem = GroceryItem(context: viewContext)
            newItem.purchasedDate = Date()
            newItem.expirationDate = Date()
            newItem.name = "Sample"

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
    
    private func editItem() {
        
    }

    
}

private let groceryItemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

func getWithinWeek(groceryItems: FetchedResults<GroceryItem>) -> [GroceryItem] {
    var weekArray: [GroceryItem] = []
    
    let currentDate = Date().addingTimeInterval(86400)
    let outerRange = Date().addingTimeInterval(604800)
    
    let range = currentDate...outerRange
    
    for item in groceryItems {
        if isSameDay(date1: item.expirationDate!, date2: Date()) {
            continue
        }
        if Calendar.current.isDateInTomorrow(item.expirationDate!) {
            weekArray.append(item)
            continue
        }
        if range.contains(item.expirationDate!){
            weekArray.append(item)
        }
    }
    return weekArray
}

func getNotWithinWeek(groceryItems: FetchedResults<GroceryItem>) -> [GroceryItem] {
    var weekArray: [GroceryItem] = []
    
    let currentDate = Date()
    
    for item in groceryItems {
        if item.expirationDate?.isInSevenDays() == false && item.expirationDate! > currentDate {
            weekArray.append(item)
        }
    }
    return weekArray
}

func getExpired(groceryItems: FetchedResults<GroceryItem>) -> [GroceryItem] {
    var weekArray: [GroceryItem] = []
    
    for item in groceryItems {
        let isntToday = !isSameDay(date1: item.expirationDate!, date2: Date())
        
        let beforeToday = item.expirationDate! < Date()
        
        if isntToday && beforeToday {
            weekArray.append(item)
        }
    }
    
    return weekArray
}

func isSameDay(date1: Date, date2: Date) -> Bool {
    let diff = Calendar.current.isDate(date1, equalTo: date2, toGranularity: .day)
    return diff
}
    
func isToday(groceryItems: FetchedResults<GroceryItem>) -> [GroceryItem] {
    var weekArray: [GroceryItem] = []
    
    for item in groceryItems {
        let diff = Calendar.current.isDateInToday(item.expirationDate!)
        
        if diff {
            weekArray.append(item)
        }
    }
    
    return weekArray
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).preferredColorScheme(.dark)
    }
}
