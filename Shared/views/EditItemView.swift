//
//  EditItemView.swift
//  Grocery Tracker
//

import CoreData
import SwiftUI
import UserNotifications

struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var item: GroceryItem

    @State private var name: String
    @State private var brand: String
    @State private var barcode: String
    @State private var packageSize: String
    @State private var packageCount: Int
    @State private var purchaseDate: Date
    @State private var expirationDate: Date
    @State private var remindersEnabled: Bool
    @State private var reminderDaysBefore: Int
    @State private var validationError: AddItemValidationError?
    @State private var persistenceError: (any Error)?
    @State private var notificationError: (any Error)?
    @State private var isSaving = false

    init(item: GroceryItem) {
        self.item = item
        name = item.name ?? ""
        brand = item.brand ?? ""
        barcode = item.barcode ?? ""
        packageSize = item.displayPackageSize ?? ""
        packageCount = item.packageCount
        purchaseDate = item.purchasedDate ?? .now
        expirationDate = item.expirationDate ?? .now
        remindersEnabled = item.remindersEnabled
        reminderDaysBefore = max(Int(item.reminderDaysBefore), 1)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Product") {
                    TextField("Item Name", text: $name)
                    TextField("Brand (Optional)", text: $brand)
                        .textContentType(.organizationName)
                    TextField("Barcode (Optional)", text: $barcode)
                        .keyboardType(.numberPad)
                        .textContentType(.none)
                }

                Section("Inventory") {
                    TextField("Package Size (for example, 12 oz)", text: $packageSize)

                    Stepper(value: $packageCount, in: 1...100) {
                        LabeledContent("Number of Packages", value: "\(packageCount)")
                    }
                }

                Section("Dates") {
                    DatePicker(
                        "Purchase Date",
                        selection: $purchaseDate,
                        displayedComponents: .date
                    )
                    DatePicker(
                        "Expiration Date",
                        selection: $expirationDate,
                        displayedComponents: .date
                    )
                }

                Section("Reminder") {
                    Toggle("Enable Notification", isOn: $remindersEnabled)
                        .tint(Color.sproutGreen)

                    if remindersEnabled {
                        Picker("Notify Me", selection: $reminderDaysBefore) {
                            ForEach(1...5, id: \.self) { day in
                                Text(day == 1 ? "1 day before" : "\(day) days before")
                                    .tag(day)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await save()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .accessibilityLabel("Saving changes")
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(isSaving || name.nilIfBlank == nil)
                }
            }
        }
        .interactiveDismissDisabled(isSaving)
        .alert("Invalid Item", item: $validationError) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            switch error {
            case .blankName:
                Text("Enter a name for the grocery item.")
            case .expirationBeforePurchase:
                Text("Choose an expiration date that is the same as or later than the purchase date.")
            }
        }
        .alert("Couldn’t Save Changes", item: $persistenceError) { _ in
            Button("OK", role: .cancel) {}
        } message: { _ in
            Text("Your changes couldn’t be saved. Please try again.")
        }
        .alert("Reminder Not Scheduled", item: $notificationError) { _ in
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: { _ in
            Text("Your changes were saved, but the expiration reminder couldn’t be scheduled.")
        }
    }

    private func save() async {
        guard !isSaving else { return }

        let validatedName: String
        do {
            validatedName = try AddItemValidator.validatedName(
                name,
                purchaseDate: purchaseDate,
                expirationDate: expirationDate
            )
        } catch let error as AddItemValidationError {
            validationError = error
            return
        } catch {
            return
        }

        isSaving = true
        defer { isSaving = false }

        let oldNotificationIdentifier = item.notificationIdentifier
        applyChanges(name: validatedName)

        var newNotificationIdentifier: String?
        if remindersEnabled {
            let details = ExpirationReminderDetails(
                itemName: validatedName,
                expirationDate: expirationDate,
                daysBefore: reminderDaysBefore
            )

            do {
                newNotificationIdentifier = try await ExpirationReminderScheduler.schedule(
                    details,
                    requestingAuthorizationIfNeeded: true
                )
                item.notificationIdentifier = newNotificationIdentifier
            } catch {
                item.notificationIdentifier = nil

                do {
                    try viewContext.save()
                    GroceryWidgetSnapshotStore.refresh(in: viewContext)
                    removeNotification(withIdentifier: oldNotificationIdentifier)
                    notificationError = error
                } catch {
                    viewContext.rollback()
                    persistenceError = error
                }
                return
            }
        } else {
            item.notificationIdentifier = nil
        }

        do {
            try viewContext.save()
            GroceryWidgetSnapshotStore.refresh(in: viewContext)
            if oldNotificationIdentifier != newNotificationIdentifier {
                removeNotification(withIdentifier: oldNotificationIdentifier)
            }
            dismiss()
        } catch {
            viewContext.rollback()
            removeNotification(withIdentifier: newNotificationIdentifier)
            persistenceError = error
        }
    }

    private func applyChanges(name: String) {
        item.name = name
        item.brand = brand.nilIfBlank
        item.barcode = (try? BarcodeNormalizer.normalize(barcode)) ?? barcode.nilIfBlank
        item.packageSize = packageSize.nilIfBlank
        item.measurement = nil
        item.quantity = Int16(packageCount)
        item.purchasedDate = purchaseDate
        item.expirationDate = expirationDate
        item.remindersEnabled = remindersEnabled
        item.reminderDaysBefore = Int16(reminderDaysBefore)
    }

    private func removeNotification(withIdentifier identifier: String?) {
        guard let identifier else { return }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}

#Preview("Edit Item") {
    let context = PersistenceController.preview.container.viewContext
    let item = GroceryItem(context: context)
    item.name = "Organic Whole Milk"
    item.brand = "Sample Dairy"
    item.barcode = "012345678905"
    item.packageSize = "1 gallon"
    item.quantity = 2
    item.purchasedDate = .now
    item.expirationDate = Calendar.current.date(byAdding: .day, value: 3, to: .now)
    item.remindersEnabled = true
    item.reminderDaysBefore = 3

    return EditItemView(item: item)
        .environment(\.managedObjectContext, context)
}
