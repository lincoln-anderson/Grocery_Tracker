//
//  ItemDetailView.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 6/13/25.
//

import CoreData
import SwiftUI
import UserNotifications

struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var item: GroceryItem

    @State private var showingEditSheet = false
    @State private var pendingCompletion: PendingGroceryCompletion?
    @State private var itemPendingDeletion: GroceryItem?
    @State private var notice: ItemDetailNotice?

    var body: some View {
        List {
            ProductHeroSection(
                imageURL: item.imageURL.flatMap(URL.init(string:))
            )

            ExpirationDetailSection(expirationDate: item.expirationDate)

            ProductInformationSection(
                brand: item.brand?.nilIfBlank,
                packageSize: item.displayPackageSize,
                barcode: item.barcode?.nilIfBlank
            )

            InventoryDetailSection(summary: item.inventorySummary)

            ItemDatesSection(
                purchaseDate: item.purchasedDate,
                expirationDate: item.expirationDate
            )
        }
        .listStyle(.insetGrouped)
        .navigationTitle(item.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if item.lifecycleState == .active {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            ItemDetailActionsBar(
                lifecycleState: item.lifecycleState,
                usedAction: { beginCompletion(as: .used) },
                discardAction: { beginCompletion(as: .discarded) },
                restoreAction: restore,
                deleteAction: { itemPendingDeletion = item }
            )
        }
        .sheet(item: $pendingCompletion) { pendingCompletion in
            CompletionQuantitySheet(completion: pendingCompletion) { packageCount in
                complete(as: pendingCompletion.status, packageCount: packageCount)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditItemView(item: item)
        }
        .alert("Delete Permanently?", item: $itemPendingDeletion) { item in
            Button("Delete", role: .destructive) {
                delete(item)
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text("\(item.displayName) will be removed permanently. This can’t be undone.")
        }
        .alert(notice?.title ?? "Item", item: $notice) { notice in
            Button("OK", role: .cancel) {
                if notice.dismissAfterAcknowledgement {
                    dismiss()
                }
            }
        } message: { notice in
            Text(notice.message)
        }
    }

    private func beginCompletion(as status: GroceryItemLifecycleStatus) {
        if item.packageCount > 1 {
            pendingCompletion = PendingGroceryCompletion(item: item, status: status)
        } else {
            complete(as: status, packageCount: 1)
        }
    }

    private func complete(
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

            if result.activeRemainder == nil {
                dismiss()
            }
        } catch {
            notice = ItemDetailNotice(
                title: "Couldn’t Update Item",
                message: "The grocery couldn’t be moved to History. Please try again."
            )
        }
    }

    private func restore() {
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
            notice = ItemDetailNotice(
                title: "Couldn’t Restore Item",
                message: "The item couldn’t be restored. Please try again."
            )
            return
        }

        guard shouldScheduleReminder, let reminderDetails else {
            dismiss()
            return
        }

        Task {
            do {
                let identifier = try await ExpirationReminderScheduler.schedule(reminderDetails)
                item.notificationIdentifier = identifier

                do {
                    try viewContext.save()
                    dismiss()
                } catch {
                    UNUserNotificationCenter.current()
                        .removePendingNotificationRequests(withIdentifiers: [identifier])
                    viewContext.rollback()
                    throw error
                }
            } catch {
                notice = ItemDetailNotice(
                    title: "Item Restored",
                    message: "The item is active again, but its expiration reminder couldn’t be scheduled.",
                    dismissAfterAcknowledgement: true
                )
            }
        }
    }

    private func delete(_ item: GroceryItem) {
        viewContext.delete(item)

        do {
            try viewContext.save()
            GroceryWidgetSnapshotStore.refresh(in: viewContext)
            dismiss()
        } catch {
            viewContext.rollback()
            notice = ItemDetailNotice(
                title: "Couldn’t Delete Item",
                message: "The item couldn’t be deleted. Please try again."
            )
        }
    }
}

private struct ItemDetailActionsBar: View {
    let lifecycleState: GroceryItemLifecycleStatus
    let usedAction: () -> Void
    let discardAction: () -> Void
    let restoreAction: () -> Void
    let deleteAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if lifecycleState == .active {
                Button {
                    usedAction()
                } label: {
                    Label("Mark Used", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    discardAction()
                } label: {
                    Label("Discard", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            } else {
                Button {
                    restoreAction()
                } label: {
                    Label("Restore", systemImage: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.sproutGreen)

                Button(role: .destructive) {
                    deleteAction()
                } label: {
                    Label("Delete", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .controlSize(.large)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

private struct ItemDetailNotice: Identifiable {
    let id = UUID()
    let title: LocalizedStringResource
    let message: LocalizedStringResource
    var dismissAfterAcknowledgement = false
}

private struct ProductHeroSection: View {
    let imageURL: URL?

    var body: some View {
        if let imageURL {
            Section {
                ProductImageView(url: imageURL, height: 220)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
    }
}

private struct ExpirationDetailSection: View {
    let expirationDate: Date?

    var body: some View {
        Section {
            HStack(spacing: 14) {
                Image(systemName: statusSymbol)
                    .font(.title2)
                    .foregroundStyle(statusColor)
                    .frame(width: 44, height: 44)
                    .background(statusColor.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(statusTitle)
                        .font(.headline)
                        .foregroundStyle(statusColor)

                    Text(statusDetail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var statusTitle: String {
        guard let expirationDate else { return "No Expiration Date" }

        if expirationDate.isExpired {
            return "Expired"
        }
        if expirationDate.isToday {
            return "Expires Today"
        }
        if expirationDate.isTomorrow {
            return "Expires Tomorrow"
        }

        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: expirationDate)
        ).day ?? 0
        return "\(max(days, 0)) Days Remaining"
    }

    private var statusDetail: String {
        expirationDate?.formatted(date: .long, time: .omitted)
            ?? "Add an expiration date to track this item."
    }

    private var statusColor: Color {
        guard let expirationDate else { return .secondary }

        if expirationDate.isExpired {
            return .red
        }
        if expirationDate.isToday ||
            expirationDate.isTomorrow ||
            expirationDate.isWithin(days: 7) {
            return .orange
        }
        return .sproutGreen
    }

    private var statusSymbol: String {
        guard let expirationDate else { return "calendar.badge.questionmark" }

        if expirationDate.isExpired {
            return "exclamationmark.triangle.fill"
        }
        if expirationDate.isToday ||
            expirationDate.isTomorrow ||
            expirationDate.isWithin(days: 7) {
            return "clock.badge.exclamationmark.fill"
        }
        return "calendar.badge.checkmark"
    }
}

private struct ProductInformationSection: View {
    let brand: String?
    let packageSize: String?
    let barcode: String?

    var body: some View {
        if brand != nil || packageSize != nil || barcode != nil {
            Section("Product") {
                if let brand {
                    LabeledContent("Brand", value: brand)
                }

                if let packageSize {
                    LabeledContent("Package Size", value: packageSize)
                }

                if let barcode {
                    LabeledContent("Barcode") {
                        Text(barcode)
                            .monospacedDigit()
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }
}

private struct InventoryDetailSection: View {
    let summary: String

    var body: some View {
        Section("Inventory") {
            LabeledContent("On Hand", value: summary)
        }
    }
}

private struct ItemDatesSection: View {
    let purchaseDate: Date?
    let expirationDate: Date?

    var body: some View {
        Section("Dates") {
            LabeledContent("Purchased") {
                Text(
                    purchaseDate?.formatted(date: .abbreviated, time: .omitted)
                        ?? "Not Available"
                )
            }

            LabeledContent("Expires") {
                Text(
                    expirationDate?.formatted(date: .abbreviated, time: .omitted)
                        ?? "Not Available"
                )
            }
        }
    }
}

#Preview("Item Detail") {
    let context = PersistenceController.preview.container.viewContext
    let item = GroceryItem(context: context)
    item.name = "Organic Whole Milk"
    item.brand = "Sample Dairy"
    item.barcode = "012345678905"
    item.packageSize = "1 gallon"
    item.quantity = 2
    item.purchasedDate = .now
    item.expirationDate = Calendar.current.date(byAdding: .day, value: 3, to: .now)

    return NavigationStack {
        ItemDetailView(item: item)
    }
    .environment(\.managedObjectContext, context)
}
