//
//  Profile.swift
//  Grocery Tracker
//

import CoreData
import SwiftUI
import UserNotifications

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \GroceryItem.completedDate, ascending: false)
        ],
        predicate: NSPredicate(
            format: "lifecycleStatus == %@",
            GroceryItemLifecycleStatus.used.rawValue
        ),
        animation: .default
    )
    private var usedItems: FetchedResults<GroceryItem>

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \GroceryItem.completedDate, ascending: false)
        ],
        predicate: NSPredicate(
            format: "lifecycleStatus == %@",
            GroceryItemLifecycleStatus.discarded.rawValue
        ),
        animation: .default
    )
    private var discardedItems: FetchedResults<GroceryItem>

    @State private var itemPendingDeletion: GroceryItem?
    @State private var notice: HistoryNotice?

    var body: some View {
        Group {
            if usedItems.isEmpty && discardedItems.isEmpty {
                ContentUnavailableView(
                    "No History Yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Groceries you use or discard will appear here.")
                )
            } else {
                List {
                    HistorySection(
                        title: "Used",
                        systemImage: "checkmark.circle.fill",
                        tint: .green,
                        items: usedItems,
                        restoreAction: restore,
                        deleteAction: { itemPendingDeletion = $0 }
                    )

                    HistorySection(
                        title: "Discarded",
                        systemImage: "trash.circle.fill",
                        tint: .orange,
                        items: discardedItems,
                        restoreAction: restore,
                        deleteAction: { itemPendingDeletion = $0 }
                    )
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("History")
        .alert(
            "Delete Permanently?",
            item: $itemPendingDeletion
        ) { item in
            Button("Delete", role: .destructive) {
                delete(item)
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text("\(item.displayName) will be removed permanently. This can’t be undone.")
        }
        .alert(
            notice?.title ?? "History",
            item: $notice
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { notice in
            Text(notice.message)
        }
    }

    private func restore(_ item: GroceryItem) {
        let reminderDetails = item.expirationDate.map {
            ExpirationReminderDetails(
                itemName: item.displayName,
                expirationDate: $0,
                daysBefore: Int(item.reminderDaysBefore)
            )
        }
        let shouldScheduleReminder = item.remindersEnabled && reminderDetails != nil

        do {
            try GroceryItemLifecycleService.restore(item, in: viewContext)
        } catch {
            notice = HistoryNotice(
                title: "Couldn’t Restore Item",
                message: "The item couldn’t be restored. Please try again."
            )
            return
        }

        guard shouldScheduleReminder, let reminderDetails else { return }

        Task {
            do {
                let identifier = try await ExpirationReminderScheduler.schedule(reminderDetails)
                item.notificationIdentifier = identifier

                do {
                    try viewContext.save()
                } catch {
                    UNUserNotificationCenter.current()
                        .removePendingNotificationRequests(withIdentifiers: [identifier])
                    viewContext.rollback()
                    throw error
                }
            } catch {
                notice = HistoryNotice(
                    title: "Item Restored",
                    message: "The item is active again, but its expiration reminder couldn’t be scheduled."
                )
            }
        }
    }

    private func delete(_ item: GroceryItem) {
        withAnimation {
            viewContext.delete(item)

            do {
                try viewContext.save()
                GroceryWidgetSnapshotStore.refresh(in: viewContext)
            } catch {
                viewContext.rollback()
                notice = HistoryNotice(
                    title: "Couldn’t Delete Item",
                    message: "The item couldn’t be deleted. Please try again."
                )
            }
        }
    }
}

private struct HistorySection: View {
    let title: LocalizedStringResource
    let systemImage: String
    let tint: Color
    let items: FetchedResults<GroceryItem>
    let restoreAction: (GroceryItem) -> Void
    let deleteAction: (GroceryItem) -> Void

    var body: some View {
        if !items.isEmpty {
            Section {
                ForEach(items) { item in
                    NavigationLink {
                        ItemDetailView(item: item)
                    } label: {
                        HistoryItemRow(item: item, tint: tint)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            restoreAction(item)
                        } label: {
                            Label("Restore", systemImage: "arrow.uturn.backward")
                        }
                        .tint(Color.sproutGreen)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteAction(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .accessibilityAction(named: "Restore") {
                        restoreAction(item)
                    }
                    .accessibilityAction(named: "Delete Permanently") {
                        deleteAction(item)
                    }
                }
            } header: {
                Label(title, systemImage: systemImage)
                    .foregroundStyle(tint)
            }
        }
    }
}

private struct HistoryItemRow: View {
    let item: GroceryItem
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.lifecycleState == .used ? "checkmark" : "trash")
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.headline)

                Text(item.inventorySummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let completedDate = item.completedDate {
                    Text(completedDate, format: .dateTime.month(.abbreviated).day().year())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct HistoryNotice: Identifiable {
    let id = UUID()
    let title: LocalizedStringResource
    let message: LocalizedStringResource
}

#Preview("History") {
    let context = PersistenceController.preview.container.viewContext
    let usedItem = GroceryItem(context: context)
    usedItem.name = "Whole Milk"
    usedItem.packageSize = "1 gallon"
    usedItem.quantity = 1
    usedItem.lifecycleState = .used
    usedItem.completedDate = .now

    let discardedItem = GroceryItem(context: context)
    discardedItem.name = "Spinach"
    discardedItem.packageSize = "5 oz"
    discardedItem.quantity = 2
    discardedItem.lifecycleState = .discarded
    discardedItem.completedDate = Calendar.current.date(byAdding: .day, value: -1, to: .now)

    return NavigationStack {
        HistoryView()
    }
    .environment(\.managedObjectContext, context)
}
