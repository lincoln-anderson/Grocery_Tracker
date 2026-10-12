//
//  AddItemView.swift
//  Grocery_Tracker
//
//  Created by lincoln anderson on 4/28/21.
//

import CoreData
import SwiftUI
import UserNotifications

struct AddItemView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @Binding var isPresented: Bool

    @State var newName: String = ""
    @State var expirationDate: Date
    @State var purchaseDate: Date
    @State var quantity: Int = 1
    @State var measurement: String = Measurements.oz.rawValue
    @State var sendNotification: Bool = true
    @State var notificationTime: Int = 3
    @State private var validationError: AddItemValidationError?
    @State private var persistenceError: (any Error)?
    @State private var notificationError: (any Error)?
    @State private var isSaving = false

    private enum ReminderError: Error {
        case authorizationDenied
    }

    enum Measurements: String, CaseIterable, Identifiable {
        case oz
        case lb
        case ml

        var id: String { rawValue }
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    Spacer(minLength: 0)

                    VStack(spacing: 20) {
                        AddItemHeader()

                        AddItemNameSection(name: $newName)

                        AddItemDatesSection(
                            purchaseDate: $purchaseDate,
                            expirationDate: $expirationDate
                        )

                        AddItemQuantitySection(
                            quantity: $quantity,
                            measurement: $measurement
                        )

                        AddItemNotificationSection(
                            sendNotification: $sendNotification,
                            notificationTime: $notificationTime
                        )

                        AddItemSaveButton(isSaving: isSaving) {
                            Task {
                                await saveItem()
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
                .frame(minHeight: geometry.size.height)
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.interactively)
        }
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
        .alert("Couldn’t Save Item", item: $persistenceError) { _ in
            Button("OK", role: .cancel) {}
        } message: { _ in
            Text("Your item couldn’t be saved. Please try again.")
        }
        .alert("Reminder Not Scheduled", item: $notificationError) { _ in
            Button("OK", role: .cancel) {
                isPresented = false
            }
        } message: { _ in
            Text("The item was saved, but its expiration reminder couldn’t be scheduled.")
        }
    }

    private func saveItem() async {
        guard !isSaving else { return }

        let validatedName: String
        do {
            validatedName = try AddItemValidator.validatedName(
                newName,
                purchaseDate: purchaseDate,
                expirationDate: expirationDate
            )
        } catch let error as AddItemValidationError {
            validationError = error
            return
        } catch {
            return
        }

        newName = validatedName
        isSaving = true
        defer { isSaving = false }

        do {
            try newItem(
                newName: validatedName,
                expirationDate: expirationDate,
                purchaseDate: purchaseDate,
                quantity: Int16(quantity),
                measurement: measurement
            )
        } catch {
            persistenceError = error
            return
        }

        guard sendNotification else {
            isPresented = false
            return
        }

        do {
            try await scheduleExpirationReminder()
            isPresented = false
        } catch {
            notificationError = error
        }
    }

    private func scheduleExpirationReminder() async throws {
        let notificationCenter = UNUserNotificationCenter.current()
        let isAuthorized = try await notificationCenter.requestAuthorization(
            options: [.alert, .sound]
        )

        guard isAuthorized else {
            throw ReminderError.authorizationDenied
        }

        let calendar = Calendar.current
        let reminderDate = try ExpirationReminderCalculator.reminderDate(
            for: expirationDate,
            daysBefore: notificationTime,
            calendar: calendar
        )

        let content = UNMutableNotificationContent()
        content.title = "\(newName) expires soon!"
        content.subtitle =
            "Expiration Date \(expirationDate.formatted(date: .abbreviated, time: .omitted))"
        content.sound = .default

        let dateComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    private func newItem(
        newName: String,
        expirationDate: Date,
        purchaseDate: Date,
        quantity: Int16,
        measurement: String
    ) throws {
        let newItem = GroceryItem(context: viewContext)
        newItem.name = newName
        newItem.expirationDate = expirationDate
        newItem.purchasedDate = purchaseDate
        newItem.quantity = quantity
        newItem.measurement = measurement

        do {
            try viewContext.save()
        } catch {
            viewContext.delete(newItem)
            throw error
        }
    }
}

private struct AddItemHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Grocery Item")
                .font(.title2.bold())
                .foregroundStyle(Color.sproutGreen)
                .accessibilityAddTraits(.isHeader)
                .padding(.top)
                .padding(.horizontal)

            Divider()
                .padding(.horizontal)
        }
    }
}

private struct AddItemNameSection: View {
    @Binding var name: String

    var body: some View {
        LabeledField(title: "Item Name") {
            TextField("Item Name", text: $name)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(.rect(cornerRadius: 10))
        }
        .padding(.horizontal)
    }
}

private struct AddItemDatesSection: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Binding var purchaseDate: Date
    @Binding var expirationDate: Date

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
            : AnyLayout(HStackLayout(spacing: 16))

        layout {
            dateField(title: "Purchase Date", selection: $purchaseDate)
            dateField(title: "Expiration Date", selection: $expirationDate)
        }
        .padding(.horizontal)
    }

    private func dateField(title: LocalizedStringKey, selection: Binding<Date>) -> some View {
        LabeledField(title: title) {
            DatePicker(title, selection: selection, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(.rect(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AddItemQuantitySection: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var pickerHeight: CGFloat = 120

    @Binding var quantity: Int
    @Binding var measurement: String

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
            : AnyLayout(HStackLayout(spacing: 16))

        LabeledField(title: "Quantity & Measurement") {
            layout {
                Picker("Quantity", selection: $quantity) {
                    ForEach(1...100, id: \.self) {
                        Text("\($0)")
                    }
                }
                .frame(maxWidth: .infinity)
                .clipped()
                .pickerStyle(.wheel)

                Picker("Measurement", selection: $measurement) {
                    ForEach(AddItemView.Measurements.allCases) { measurement in
                        Text(measurement.rawValue.capitalized)
                    }
                }
                .frame(maxWidth: .infinity)
                .clipped()
                .pickerStyle(.wheel)
            }
            .frame(
                minHeight: dynamicTypeSize.isAccessibilitySize
                    ? pickerHeight * 2
                    : pickerHeight
            )
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(.rect(cornerRadius: 10))
        }
        .padding(.horizontal)
    }
}

private struct AddItemNotificationSection: View {
    @Binding var sendNotification: Bool
    @Binding var notificationTime: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expiration Alert")
                .font(.headline)
                .padding(.bottom, 2)

            Toggle("Enable Notification", isOn: $sendNotification)
                .tint(Color.sproutGreen)

            Text("Remind me this many days before expiration:")
                .font(.subheadline)
                .foregroundStyle(Color.sproutGreen)

            Picker("Days Before Expiration", selection: $notificationTime) {
                ForEach(1...5, id: \.self) { day in
                    Text("\(day)")
                }
            }
            .pickerStyle(.segmented)
            .disabled(!sendNotification)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(.rect(cornerRadius: 10))
        .padding(.horizontal)
    }
}

private struct AddItemSaveButton: View {
    let isSaving: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(isSaving ? "Saving…" : "Save Item")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(Color.sproutGreen)
                .background(Color(.systemGray6))
                .clipShape(.rect(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                .padding(.horizontal)
        }
        .disabled(isSaving)
    }
}

private struct LabeledField<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.sproutGreen)

            content
        }
    }
}

#Preview("Add Item — Light") {
    @Previewable @State var isShowing = true

    AddItemView(
        isPresented: $isShowing,
        expirationDate: .now,
        purchaseDate: .now
    )
    .environment(
        \.managedObjectContext,
        PersistenceController.preview.container.viewContext
    )
}

#Preview("Add Item — Dark") {
    @Previewable @State var isShowing = true

    AddItemView(
        isPresented: $isShowing,
        expirationDate: .now,
        purchaseDate: .now
    )
    .environment(
        \.managedObjectContext,
        PersistenceController.preview.container.viewContext
    )
    .preferredColorScheme(.dark)
}
