//  ContentView.swift
//  Grocery_Tracker

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

    var containerWidth: CGFloat = UIScreen.main.bounds.width - 32.0
    var containerHeight: CGFloat = UIScreen.main.bounds.height

    let columns = [GridItem(.adaptive(minimum: 180))]

    var body: some View {
        VStack {
            ScrollView {
                if groceryItems.isEmpty {
                    Text("Tap the \"Add Item\" button to add your groceries and begin tracking the expiration dates")
                        .bold()
                        .font(.title)
                        .multilineTextAlignment(.center)
                }

                LazyVGrid(columns: columns, spacing: 15, pinnedViews: .sectionHeaders) {

                    let expired = expiredItems()
                    if !expired.isEmpty {
                        let expiredLabel = "These \(expired.count) item" + (expired.count == 1 ? " has" : "s have") + " expired!"
                        Section(header:
                            Text(expiredLabel)
                                .bold()
                                .font(.title)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        ) {
                            ForEach(expired) { item in
                                GroceryItemGridView(item: item)
                            }
                        }
                    }

                    let today = todayItems()
                    if !today.isEmpty {
                        let todayLabel = "These \(today.count) item" + (today.count == 1 ? " expires" : "s expire") + " today"
                        Section(header:
                            Text(todayLabel)
                                .bold()
                                .font(.title)
                                .multilineTextAlignment(.center)
                        ) {
                            ForEach(today) { item in
                                GroceryItemGridView(item: item)
                            }
                        }
                    }

                    let soon = withinWeekItems()
                    if !soon.isEmpty {
                        let soonLabel = "These \(soon.count) item" + (soon.count == 1 ? " will" : "s will") + " expire within 7 days"
                        Section(header:
                            Text(soonLabel)
                                .bold()
                                .font(.title)
                                .multilineTextAlignment(.center)
                        ) {
                            ForEach(soon) { item in
                                GroceryItemGridView(item: item)
                            }
                        }
                    }

                    let later = afterWeekItems()
                    if !later.isEmpty {
                        let laterLabel = "These \(later.count) item" + (later.count == 1 ? " expires" : "s expire") + " after 7 days"
                        Section(header:
                            Text(laterLabel)
                                .bold()
                                .font(.title)
                                .multilineTextAlignment(.center)
                        ) {
                            ForEach(later) { item in
                                GroceryItemGridView(item: item)
                            }
                        }
                    }
                }
            }

            Spacer()

            VStack {
                Button(action: {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                        if success {
                            print("All set!")
                        } else if let error = error {
                            print(error.localizedDescription)
                        }
                    }
                    self.showingAddSheet.toggle()
                }) {
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
                }
                .sheet(isPresented: $showingAddSheet) {
                    AddItemView(isPresented: $showingAddSheet, expirationDate: Date(), purchaseDate: Date(), quantity: 1).environment(\.managedObjectContext, self.viewContext)
                }

                Button(action: { self.showingRemoveSheet.toggle() }) {
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
                }
                .sheet(isPresented: $showingRemoveSheet) {
                    UsedGroceryView(isPresented: $showingRemoveSheet, filterString: $testString).environment(\.managedObjectContext, self.viewContext)
                }
            }

            if containerHeight < 1000 {
                Spacer()
            }
        }
    }

    private func expiredItems() -> [GroceryItem] {
        groceryItems.filter { $0.expirationDate?.isExpired == true }
    }

    private func todayItems() -> [GroceryItem] {
        groceryItems.filter { $0.expirationDate?.isToday == true }
    }

    private func withinWeekItems() -> [GroceryItem] {
        groceryItems.filter {
            guard let date = $0.expirationDate else { return false }
            return !date.isToday && (date.isTomorrow || date.isWithin(days: 7))
        }
    }

    private func afterWeekItems() -> [GroceryItem] {
        groceryItems.filter {
            guard let date = $0.expirationDate else { return false }
            return !date.isWithin(days: 7) && date > Date()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
