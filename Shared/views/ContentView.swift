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
    

    let columns = [
        GridItem(.adaptive(minimum: 180))
    ]

    var body: some View {
        
        VStack{
            ScrollView {
                LazyVGrid(columns: columns, spacing: 15, pinnedViews: .sectionHeaders) {
                    if getWithinWeek(groceryItems: groceryItems).count > 0 {
                        Section(header:
                                    Text("These \(getWithinWeek(groceryItems: groceryItems).count) items will expire within 7 days").bold()
                            .font(.title3)
                        ) {
                            ForEach(getWithinWeek(groceryItems: groceryItems)) { groceryItem in
                                GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!)
                            }
                        }
                    }
                    if getNotWithinWeek(groceryItems: groceryItems).count > 0 {
                        Section(header:
                                    Text("These \(getNotWithinWeek(groceryItems: groceryItems).count) expire after more than 7 days").bold()
                            .font(.title2)
                        ) {
                            ForEach(getNotWithinWeek(groceryItems: groceryItems)) { groceryItem in
                                GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!)
                            }
                        }
                    }
                    
                    if getExpired(groceryItems: groceryItems).count > 0 {
                        let _ = print(getExpired(groceryItems: groceryItems).count)
                        Section(header:
                                    Text("These \(getNotWithinWeek(groceryItems: groceryItems).count) Have expired!").bold()
                            .font(.title2)
                            .foregroundColor(.red)

                        ) {
                            ForEach(getExpired(groceryItems: groceryItems)) { groceryItem in
                                GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!)
                            }
                        }
                    }
                }
            }
            Spacer()
            
            HStack{
                
                Spacer()
            
                Button(action: {self.showingRemoveSheet.toggle()}, label: {
                        Text("-")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(width: 80, height: 80)
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
                
                Spacer()
                
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
                                Text("+")
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .frame(width: 80, height: 80)
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
                
                Spacer()
            
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
    
    for item in groceryItems {
        if item.expirationDate?.isInSevenDays() == true {
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
    
    let currentDate = Date()
    
    for item in groceryItems {
        if item.expirationDate! < currentDate && item.expirationDate! != Date() {
            weekArray.append(item)
        }
    }
    
    let _ = print("String(getExpired(groceryItems: groceryItems).count)")
    
    return weekArray
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).preferredColorScheme(.dark)
    }
}
