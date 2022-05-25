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
        GridItem(.adaptive(minimum: 150))
    ]

    var body: some View {
        
        VStack{
            ScrollView {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(groceryItems) { groceryItem in
                            GroceryItemGridView(passedGroceryItemName: groceryItem.name!, passedGroceryItemExpirationDate: groceryItem.expirationDate!)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).preferredColorScheme(.dark)
    }
}
