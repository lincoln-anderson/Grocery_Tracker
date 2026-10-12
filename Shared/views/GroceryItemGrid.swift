//  ContentView.swift
//  Grocery_Tracker

import SwiftUI
import CoreData
import UserNotifications

struct GroceryItemGrid: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GroceryItem.expirationDate, ascending: true)],
        predicate: NSPredicate(
            format: "lifecycleStatus == nil OR lifecycleStatus == %@",
            GroceryItemLifecycleStatus.active.rawValue
        ),
        animation: .default)
    private var groceryItems: FetchedResults<GroceryItem>
    
    @State private var showingAddSheet = false
    @State private var pendingCompletion: PendingGroceryCompletion?
    @State private var completionError: (any Error)?
    
    private let columns = [GridItem(.adaptive(minimum: 260), spacing: 16)]

    var body: some View {
        Group {
            if groceryItems.isEmpty {
                GroceryEmptyState(addAction: { showingAddSheet = true })
            } else if horizontalSizeClass == .regular {
                GroceryGridContent(
                    sections: buildSections(from: groceryItems),
                    columns: columns,
                    onComplete: beginCompletion
                )
            } else {
                GroceryListContent(
                    sections: buildSections(from: groceryItems),
                    onComplete: beginCompletion
                )
            }
        }
        .navigationTitle("Groceries")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddItemView(
                isPresented: $showingAddSheet,
                expirationDate: .now,
                purchaseDate: .now,
                quantity: 1
            )
        }
        .sheet(item: $pendingCompletion) { pendingCompletion in
            CompletionQuantitySheet(completion: pendingCompletion) { packageCount in
                complete(
                    pendingCompletion.item,
                    as: pendingCompletion.status,
                    packageCount: packageCount
                )
            }
        }
        .alert("Couldn’t Update Item", item: $completionError) { _ in
            Button("OK", role: .cancel) {}
        } message: { _ in
            Text("The grocery couldn’t be moved to History. Please try again.")
        }
    }

    func buildSections(from items: FetchedResults<GroceryItem>) -> [GrocerySection] {
        let expired = items.filter { $0.expirationDate?.isExpired == true }
        let today = items.filter { $0.expirationDate?.isToday == true }
        let soon = items.filter {
            guard let date = $0.expirationDate else { return false }
            return !date.isToday && (date.isTomorrow || date.isWithin(days: 7))
        }
        let later = items.filter {
            guard let date = $0.expirationDate else { return false }
            return !date.isWithin(days: 7) && date > Date()
        }

        return [
            expired.isEmpty ? nil : GrocerySection(title: "Expired", color: .red, items: expired),
            today.isEmpty ? nil : GrocerySection(title: "Expires Today", color: .orange, items: today),
            soon.isEmpty ? nil : GrocerySection(title: "Expires Soon", color: .orange, items: soon),
            later.isEmpty ? nil : GrocerySection(title: "Expires Later", color: .secondary, items: later),
        ].compactMap { $0 }
    }

    private func beginCompletion(
        _ item: GroceryItem,
        _ status: GroceryItemLifecycleStatus
    ) {
        if item.packageCount > 1 {
            pendingCompletion = PendingGroceryCompletion(item: item, status: status)
        } else {
            complete(item, as: status, packageCount: 1)
        }
    }

    private func complete(
        _ item: GroceryItem,
        as status: GroceryItemLifecycleStatus,
        packageCount: Int
    ) {
        do {
            let result = try GroceryItemLifecycleService.complete(
                item,
                as: status,
                packageCount: packageCount,
                in: viewContext
            )

            if let identifier = result.notificationIdentifierToCancel {
                let center = UNUserNotificationCenter.current()
                center.removePendingNotificationRequests(withIdentifiers: [identifier])
                center.removeDeliveredNotifications(withIdentifiers: [identifier])
            }
        } catch {
            completionError = error
        }
    }
}

private struct GroceryEmptyState: View {
    let addAction: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Groceries Yet", systemImage: "basket")
        } description: {
            Text("Add a grocery to track its expiration date and receive a reminder before it expires.")
        } actions: {
            Button(action: addAction) {
                Label("Add Item", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.sproutGreen)
        }
    }
}

private struct GroceryListContent: View {
    let sections: [GrocerySection]
    let onComplete: (GroceryItem, GroceryItemLifecycleStatus) -> Void

    var body: some View {
        List {
            ForEach(sections, id: \.title) { section in
                GroceryItemGridSection(
                    section: section,
                    cardStyle: .list,
                    onComplete: onComplete
                )
            }
        }
        .listStyle(.insetGrouped)
    }
}

private struct GroceryGridContent: View {
    let sections: [GrocerySection]
    let columns: [GridItem]
    let onComplete: (GroceryItem, GroceryItemLifecycleStatus) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16, pinnedViews: .sectionHeaders) {
                ForEach(sections, id: \.title) { section in
                    GroceryItemGridSection(
                        section: section,
                        cardStyle: .grid,
                        onComplete: onComplete
                    )
                }
            }
            .padding(.horizontal)
        }
        .swipeActionsContainer()
    }
}

struct PendingGroceryCompletion: Identifiable {
    let item: GroceryItem
    let status: GroceryItemLifecycleStatus

    var id: NSManagedObjectID {
        item.objectID
    }
}

struct CompletionQuantitySheet: View {
    @Environment(\.dismiss) private var dismiss

    let completion: PendingGroceryCompletion
    let confirmAction: (Int) -> Void

    @State private var selectedPackageCount = 1

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(
                        value: $selectedPackageCount,
                        in: 1...completion.item.packageCount
                    ) {
                        LabeledContent(
                            "Packages",
                            value: "\(selectedPackageCount) of \(completion.item.packageCount)"
                        )
                    }
                } footer: {
                    Text(footerText)
                }
            }
            .navigationTitle(actionTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(actionTitle) {
                        confirmAction(selectedPackageCount)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var actionTitle: String {
        completion.status == .used ? "Mark Used" : "Discard"
    }

    private var footerText: String {
        let destination = completion.status == .used ? "Used" : "Discarded"
        return "The selected packages will move to the \(destination) section in History."
    }
}





struct SproutsButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.sproutGreen)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(.rect(cornerRadius: 12))
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





#Preview("Grocery Grid — Dark") {
    GroceryItemGrid()
        .environment(
            \.managedObjectContext,
            PersistenceController.preview.container.viewContext
        )
        .preferredColorScheme(.dark)
}
