//  ContentView.swift
//  Grocery_Tracker

import SwiftUI
import CoreData
import UserNotifications

struct Git: Codable, Identifiable {
    let id: Int
    let login: String
}

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
            NavigationStack{
                ScrollView {
                    if groceryItems.isEmpty {
                        Text("Tap the \"Add Item\" button to add your groceries and begin tracking the expiration dates")
                            .bold()
                            .font(.title)
                            .foregroundColor(.sproutGreen)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    let sections = buildSections(from: groceryItems)
                    LazyVGrid(columns: columns, spacing: 15, pinnedViews: .sectionHeaders) {
                        ForEach(sections, id: \.title) { section in
                            GroceryItemGridSection(section: section)
                        }
                    }
                }
                AddandRemoveButtonView(showingAddSheet: $showingAddSheet, showingRemoveSheet: $showingRemoveSheet, filterText: $testString)
            }
            Spacer()
        }
    }
    
    func buildSections(from items: FetchedResults<GroceryItem>) -> [GrocerySection] {
        let expired = groceryItems.filter { $0.expirationDate?.isExpired == true }
        let today = groceryItems.filter { $0.expirationDate?.isToday == true }
        let soon = groceryItems.filter {
            guard let date = $0.expirationDate else { return false }
            return !date.isToday && (date.isTomorrow || date.isWithin(days: 7))
        }
        let later = groceryItems.filter {
            guard let date = $0.expirationDate else { return false }
            return !date.isWithin(days: 7) && date > Date()
        }
        
        let sections = [
            expired.isEmpty ? nil : GrocerySection(title: "Expired", color: .red, items: expired),
            today.isEmpty ? nil : GrocerySection(title: "Expires Today", color: .yellow, items: today),
            soon.isEmpty ? nil : GrocerySection(title: "Expires Soon", color: .sproutGreen, items: soon),
            later.isEmpty ? nil : GrocerySection(title: "Expires Later", color: .sproutGreen, items: later),
        ].compactMap { $0 }
        print(sections)
        return sections
        
    }
    
}





struct SproutsButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.sproutGreen)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.05 : 0.1), radius: 2, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .padding(.horizontal)
    }
}

struct GrocerySection {
    let title: String
    let color: Color
    let items: [GroceryItem]
}





struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GroceryItemGrid()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
