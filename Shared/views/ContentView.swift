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
    
    @State var testString = "string"
    
    var containerWidth:CGFloat = UIScreen.main.bounds.width - 32.0
    

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
                    //is expired
                    if getExpired(groceryItems: groceryItems).count > 0 {
                        if getExpired(groceryItems: groceryItems).count == 1 {
                            Section(header:
                                        Text("This \(getExpired(groceryItems: groceryItems).count) item has expired!").bold()
                                .font(.title)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)

                            ) {
                                ForEach(getExpired(groceryItems: groceryItems)) { groceryItem in
                                    GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!)
                                }
                            }
                        } else {
                            Section(header:
                                        Text("These \(getExpired(groceryItems: groceryItems).count) Have expired!").bold()
                                .font(.title)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)

                            ) {
                                ForEach(getExpired(groceryItems: groceryItems)) { groceryItem in
                                    GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!)
                                }
                            }
                        }
                    }
                    // expires today section
                    if isToday(groceryItems: groceryItems).count > 0 {
                        if isToday(groceryItems: groceryItems).count == 1 {
                            Section(header:
                                        Text("This 1 item expires today").bold()
                                .font(.title)
                                .multilineTextAlignment(.center)
                            ) {
                                ForEach(isToday(groceryItems: groceryItems)) { groceryItem in
                                    GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!)
                                }
                            }
                        } else {
                            Section(header:
                                        Text("These \(isToday(groceryItems: groceryItems).count) items expire today").bold()
                                .font(.title)
                                .multilineTextAlignment(.center)
                            ) {
                                ForEach(isToday(groceryItems: groceryItems)) { groceryItem in
                                    GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!)
                                }
                            }
                        }
                    }
                    
                    //expires within week section
                    if getWithinWeek(groceryItems: groceryItems).count > 0 {
                        if getWithinWeek(groceryItems: groceryItems).count == 1 {
                            Section(header:
                                        Text("This 1 item will expire within 7 days").bold()
                                .font(.title)
                                .multilineTextAlignment(.center)
                            ) {
                                ForEach(getWithinWeek(groceryItems: groceryItems)) { groceryItem in
                                    GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!)
                                }
                            }
                        } else {
                            Section(header:
                                        Text("These \(getWithinWeek(groceryItems: groceryItems).count) items will expire within 7 days").bold()
                                .font(.title)
                                .multilineTextAlignment(.center)
                            ) {
                                ForEach(getWithinWeek(groceryItems: groceryItems)) { groceryItem in
                                    GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!)
                                }
                            }
                        }
                    }
                    
                    //expires after 7 days
                    if getNotWithinWeek(groceryItems: groceryItems).count > 0 {
                        if getNotWithinWeek(groceryItems: groceryItems).count == 1 {
                            Section(header:
                                        Text("This \(getNotWithinWeek(groceryItems: groceryItems).count) item will expire in more than 7 days").bold()
                                .font(.title)
                                .multilineTextAlignment(.center)
                            ) {
                                ForEach(getNotWithinWeek(groceryItems: groceryItems)) { groceryItem in
                                    GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!)
                                }
                            }
                        } else {
                            Section(header:
                                        Text("These \(getNotWithinWeek(groceryItems: groceryItems).count) items expire after more than 7 days").bold()
                                .font(.title)
                                .multilineTextAlignment(.center)
                            ) {
                                ForEach(getNotWithinWeek(groceryItems: groceryItems)) { groceryItem in
                                    GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!)
                                }
                            }
                        }
                    }
                    
                }
            }
            Spacer()
            
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
                
                                AddItemView(isPresented: $showingAddSheet, expirationDate: Date(), purchaseDate: Date()).environment(\.managedObjectContext, self.viewContext)
                
                            }
                
                Button(action: {self.showingRemoveSheet.toggle()}, label: {
                        Text("Delete Item")
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
        }
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
    print(weekArray.count)
    return weekArray
}

func getExpired(groceryItems: FetchedResults<GroceryItem>) -> [GroceryItem] {
    var weekArray: [GroceryItem] = []
    
    let currentDate = Date()
    
    for item in groceryItems {
        if item.expirationDate! < currentDate && !isSameDay(date1: currentDate, date2: item.expirationDate!) {
            weekArray.append(item)
        }
    }
    
    return weekArray
}

func isSameDay(date1: Date, date2: Date) -> Bool {
    let diff = Calendar.current.dateComponents([.day], from: date1, to: date2)
    if diff.day == 0 {
        return true
    } else {
        return false
    }
}
    
func isToday(groceryItems: FetchedResults<GroceryItem>) -> [GroceryItem] {
    var weekArray: [GroceryItem] = []
    
    for item in groceryItems {
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: item.expirationDate!)
        
        if diff.day == 0 {
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
