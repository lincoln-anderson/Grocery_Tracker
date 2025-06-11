//  ContentView.swift
//  Grocery_Tracker

import SwiftUI
import CoreData
import UserNotifications

struct Git: Codable, Identifiable {
    let id: Int
    let login: String
}

//func fetchGit() async throws -> Git {
//    let url = URL(string: "https://api.github.com/users/lincoln-anderson")
//    let (data, _) = try await URLSession.shared.data(from: url!)
//    return try JSONDecoder().decode(Git.self, from: data)
//}

struct GroceryItemGrid: View {
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
    @State var testString = ""
    @State private var git = Git(id: 1, login: "lincoln")
    @State private var scannedCode: String? = nil
    @State private var showingScanner = false
    
    var containerWidth: CGFloat = UIScreen.main.bounds.width - 32.0
    var containerHeight: CGFloat = UIScreen.main.bounds.height
    
    let columns = [GridItem(.adaptive(minimum: 180))]
    
    
    
    
    
    var body: some View {
        VStack {
            //            if #available(iOS 15.0, *) {
            //                Text(git.login)
            //                    .task {
            //                        do {
            //                            git = try await fetchGit()
            //                        } catch {
            //                            print("bad")
            //                        }
            //                    }
            //            } else {
            //                // Fallback on earlier versions
            //            }
            ScrollView {
                if groceryItems.isEmpty {
                    Text("Tap the \"Add Item\" button to add your groceries and begin tracking the expiration dates")
                        .bold()
                        .font(.title)
                        .foregroundColor(.sproutGreen)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                LazyVGrid(columns: columns, spacing: 15, pinnedViews: .sectionHeaders) {
                    let expired = groceryItems.filter { $0.expirationDate?.isExpired == true }
                    if !expired.isEmpty {
                        let expiredLabel = "\(expired.count != 1 ? "These" : "This") \(expired.count) item" + (expired.count == 1 ? " has" : "s have") + " expired!"
                        Section(header: SectionHeader(text: expiredLabel, color: .red)) {
                            ForEach(expired) { item in
                                GroceryItemGridView(item: item)
                            }
                        }
                    }
                    let today = groceryItems.filter { $0.expirationDate?.isToday == true }
                    
                    if !today.isEmpty {
                        let todayLabel = "\(today.count != 1 ? "These" : "This") \(today.count) item" + (today.count == 1 ? " expires" : "s expire") + " today"
                        Section(header: SectionHeader(text: todayLabel, color: .sproutGreen)) {
                            ForEach(today) { item in
                                GroceryItemGridView(item: item)
                            }
                        }
                    }
                    
                    let soon = groceryItems.filter {
                        guard let date = $0.expirationDate else { return false }
                        return !date.isToday && (date.isTomorrow || date.isWithin(days: 7))
                    }
                    if !soon.isEmpty {
                        let soonLabel = "\(soon.count != 1 ? "These" : "This") \(soon.count) item" + (soon.count == 1 ? " will" : "s will") + " expire within a week"
                        Section(header: SectionHeader(text: soonLabel, color: .sproutGreen)) {
                            ForEach(soon) { item in
                                GroceryItemGridView(item: item)
                            }
                        }
                    }
                    
                    let later = groceryItems.filter {
                        guard let date = $0.expirationDate else { return false }
                        return !date.isWithin(days: 7) && date > Date()
                    }
                    if !later.isEmpty {
                        let laterLabel = "\(later.count != 1 ? "These" : "This") \(later.count) item" + (later.count == 1 ? " expires" : "s expire") + " after a week"
                        Section(header: SectionHeader(text: laterLabel, color: .sproutGreen)) {
                            ForEach(later) { item in
                                GroceryItemGridView(item: item)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
//            VStack(spacing: 20) {
//                if let code = scannedCode {
//                    Text("Scanned Barcode: \(code)")
//                        .padding()
//                }
//
//                Button("Scan Barcode") {
//                    showingScanner = true
//                }
//                .sheet(isPresented: $showingScanner) {
//                    BarcodeScannerView(ScannedCode: $scannedCode)
//                }
//            }
//            .padding()
            
            HStack {
                Button("Add Item") {
                    showingAddSheet = true
                }
                .buttonStyle(SproutsButtonStyle(color: .green))
                .sheet(isPresented: $showingAddSheet) {
                    AddItemView(
                        isPresented: $showingAddSheet,
                        expirationDate: Date(),
                        purchaseDate: Date(),
                        quantity: 1
                    )
                    .environment(\.managedObjectContext, viewContext)
                }
                
                
                Button("Mark as Used") {
                    showingRemoveSheet = true
                }
                .buttonStyle(SproutsButtonStyle(color: .green))
                .sheet(isPresented: $showingRemoveSheet) {
                    UsedGroceryView(
                        isPresented: $showingRemoveSheet,
                        filterString: $testString
                    )
                    .environment(\.managedObjectContext, viewContext)
                }
                
                
            }
            .padding(.bottom, 8)
            
            if containerHeight < 1000 {
                Spacer()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GroceryItemGrid()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
