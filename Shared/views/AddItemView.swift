//
//  AddItemView.swift
//  Grocery_Tracker
//
//  Created by lincoln anderson on 4/28/21.
//

import CoreData
import SwiftUI
import UserNotifications

private enum ProductLookupState: Equatable {
    case idle
    case loading
    case found(name: String, details: String?)
    case notFound
    case failed
}

struct AddItemView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @Binding var isPresented: Bool

    @State var newName: String = ""
    @State var expirationDate: Date
    @State var purchaseDate: Date
    @State var quantity: Int = 1
    @State var sendNotification: Bool = true
    @State var notificationTime: Int = 3
    @State private var barcode = ""
    @State private var brand = ""
    @State private var packageSize = ""
    @State private var productImageURL: URL?
    @State private var showingScanner = false
    @State private var scannerError: BarcodeScannerError?
    @State private var productLookupState = ProductLookupState.idle
    @State private var validationError: AddItemValidationError?
    @State private var persistenceError: (any Error)?
    @State private var notificationError: (any Error)?
    @State private var isSaving = false

    private let productLookupService = OpenFoodFactsProductLookupService()

    private enum ReminderError: Error {
        case authorizationDenied
    }

    var body: some View {
        NavigationStack {
            Form {
                AddItemProductSection(
                    name: $newName,
                    barcode: Binding(
                        get: { barcode },
                        set: { value in
                            barcode = value
                            productLookupState = .idle
                            productImageURL = nil
                        }
                    ),
                    brand: $brand,
                    imageURL: productImageURL,
                    lookupState: productLookupState,
                    scanAction: { showingScanner = true },
                    lookupAction: {
                        Task {
                            await lookupProduct(barcode)
                        }
                    }
                )

                AddItemInventorySection(
                    packageSize: $packageSize,
                    packageCount: $quantity
                )

                AddItemDatesSection(
                    purchaseDate: $purchaseDate,
                    expirationDate: $expirationDate
                )

                AddItemNotificationSection(
                    sendNotification: $sendNotification,
                    notificationTime: $notificationTime
                )
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Grocery Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await saveItem()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .accessibilityLabel("Saving item")
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(isSaving || newName.nilIfBlank == nil)
                }
            }
        }
        .sheet(isPresented: $showingScanner) {
            BarcodeScannerSheet(
                onScan: { code in
                    barcode = code
                    showingScanner = false

                    Task {
                        await lookupProduct(code)
                    }
                },
                onError: { error in
                    scannerError = error
                    showingScanner = false
                }
            )
        }
        .alert("Barcode Scanner Unavailable", item: $scannerError) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            switch error {
            case .unsupported:
                Text("Barcode scanning isn’t supported on this device. Enter the barcode manually instead.")
            case .cameraUnavailable:
                Text("The camera isn’t available. Check camera permission in Settings or enter the barcode manually.")
            case .invalidBarcode:
                Text("That barcode couldn’t be read. Try scanning again or enter its digits manually.")
            case .scanningFailed:
                Text("Scanning couldn’t start. Please try again or enter the barcode manually.")
            }
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

    private func lookupProduct(_ code: String) async {
        productLookupState = .loading

        do {
            let product: ProductLookupResult
            if let savedProduct = try savedProduct(for: code) {
                product = savedProduct
            } else {
                product = try await productLookupService.product(for: code)
            }
            let detailValues = [product.brand, product.quantity].compactMap { $0 }
            let details = detailValues.isEmpty ? nil : detailValues.formatted()

            barcode = product.barcode.isEmpty ? code : product.barcode
            brand = product.brand ?? ""
            packageSize = product.quantity ?? ""
            productImageURL = product.imageURL
            if newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                newName = product.name
            }
            productLookupState = .found(name: product.name, details: details)
        } catch ProductLookupError.productNotFound,
                ProductLookupError.missingProductName {
            productLookupState = .notFound
        } catch is CancellationError {
            return
        } catch {
            productLookupState = .failed
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

        let savedItem: GroceryItem
        do {
            savedItem = try newItem(
                newName: validatedName,
                expirationDate: expirationDate,
                purchaseDate: purchaseDate,
                quantity: Int16(quantity),
                barcode: barcode,
                brand: brand,
                packageSize: packageSize,
                imageURL: productImageURL,
                remindersEnabled: sendNotification,
                reminderDaysBefore: Int16(notificationTime)
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
            guard let notificationIdentifier = savedItem.notificationIdentifier else {
                throw ReminderError.authorizationDenied
            }
            try await scheduleExpirationReminder(identifier: notificationIdentifier)
            isPresented = false
        } catch {
            savedItem.notificationIdentifier = nil
            try? viewContext.save()
            notificationError = error
        }
    }

    private func scheduleExpirationReminder(identifier: String) async throws {
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
            identifier: identifier,
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
        barcode: String,
        brand: String,
        packageSize: String,
        imageURL: URL?,
        remindersEnabled: Bool,
        reminderDaysBefore: Int16
    ) throws -> GroceryItem {
        let newItem = GroceryItem(context: viewContext)
        newItem.name = newName
        newItem.expirationDate = expirationDate
        newItem.purchasedDate = purchaseDate
        newItem.quantity = quantity
        newItem.measurement = nil
        newItem.barcode = (try? BarcodeNormalizer.normalize(barcode))
            ?? barcode.nilIfBlank
        newItem.brand = brand.nilIfBlank
        newItem.packageSize = packageSize.nilIfBlank
        newItem.imageURL = imageURL?.absoluteString
        newItem.lifecycleState = .active
        newItem.remindersEnabled = remindersEnabled
        newItem.reminderDaysBefore = reminderDaysBefore
        newItem.notificationIdentifier = remindersEnabled ? UUID().uuidString : nil

        do {
            try viewContext.save()
            GroceryWidgetSnapshotStore.refresh(in: viewContext)
        } catch {
            viewContext.delete(newItem)
            throw error
        }

        return newItem
    }

    private func savedProduct(for code: String) throws -> ProductLookupResult? {
        let normalizedBarcode = try BarcodeNormalizer.normalize(code)
        let request = GroceryItem.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "barcode == %@", normalizedBarcode)
        request.sortDescriptors = [NSSortDescriptor(key: "purchasedDate", ascending: false)]

        guard let item = try viewContext.fetch(request).first,
              let name = item.name?.nilIfBlank else {
            return nil
        }

        return ProductLookupResult(
            barcode: normalizedBarcode,
            name: name,
            brand: item.brand?.nilIfBlank,
            quantity: item.packageSize?.nilIfBlank,
            imageURL: item.imageURL.flatMap(URL.init(string:))
        )
    }
}

private struct AddItemProductSection: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Binding var name: String
    @Binding var barcode: String
    @Binding var brand: String
    let imageURL: URL?
    let lookupState: ProductLookupState
    let scanAction: () -> Void
    let lookupAction: () -> Void

    var body: some View {
        let buttonLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))

        Section("Product") {
            if let imageURL {
                ProductImageView(url: imageURL)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }

            TextField("Item Name", text: $name)

            TextField("Brand (Optional)", text: $brand)
                .textContentType(.organizationName)

            TextField("Barcode (Optional)", text: $barcode)
                .keyboardType(.numberPad)
                .textContentType(.none)

            buttonLayout {
                Button(action: scanAction) {
                    Label("Scan Barcode", systemImage: "barcode.viewfinder")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.sproutGreen)

                Button(action: lookupAction) {
                    Label("Look Up", systemImage: "magnifyingglass")
                }
                .buttonStyle(.bordered)
                .disabled(
                    barcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || lookupState == .loading
                )
            }
            .controlSize(.large)

            ProductLookupStatusView(state: lookupState)
        }
    }
}

private struct AddItemInventorySection: View {
    @Binding var packageSize: String
    @Binding var packageCount: Int

    var body: some View {
        Section("Inventory") {
            TextField("Package Size (for example, 12 oz)", text: $packageSize)

            Stepper(value: $packageCount, in: 1...100) {
                LabeledContent("Number of Packages", value: "\(packageCount)")
            }

            LabeledContent("Total", value: inventorySummary)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Inventory total: \(inventorySummary)")
        }
    }

    private var inventorySummary: String {
        guard let size = packageSize.nilIfBlank else {
            return packageCount == 1 ? "1 package" : "\(packageCount) packages"
        }

        return packageCount == 1 ? size : "\(packageCount) × \(size)"
    }
}

private struct ProductLookupStatusView: View {
    let state: ProductLookupState

    var body: some View {
        Group {
            switch state {
        case .idle:
            Text("Scan a package or enter its barcode to look up the product.")
                .foregroundStyle(.secondary)
        case .loading:
            ProgressView("Looking up product…")
        case let .found(name, details):
            VStack(alignment: .leading, spacing: 2) {
                Label("Found: \(name)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.sproutGreen)

                if let details {
                    Text(details)
                        .foregroundStyle(.secondary)
                }
            }
        case .notFound:
            Label(
                "Product not found. You can still enter the item name manually.",
                systemImage: "questionmark.circle"
            )
            .foregroundStyle(.secondary)
        case .failed:
            Label(
                "Product lookup failed. Check your connection and try again.",
                systemImage: "wifi.exclamationmark"
            )
            .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
    }
}

struct ProductImageView: View {
    let url: URL
    var height: CGFloat = 140

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("Product package")
            case .failure:
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Product image unavailable")
            case .empty:
                ProgressView()
                    .accessibilityLabel("Loading product image")
            @unknown default:
                EmptyView()
            }
        }
        .frame(height: height)
        .clipShape(.rect(cornerRadius: 12))
    }
}

private struct BarcodeScannerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onScan: (String) -> Void
    let onError: (BarcodeScannerError) -> Void

    var body: some View {
        NavigationStack {
            BarcodeScannerView(onScan: onScan, onError: onError)
                .ignoresSafeArea(edges: .bottom)
                .safeAreaInset(edge: .top) {
                    Text("Point the camera at a grocery barcode, then tap the highlighted code.")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.thinMaterial)
                }
                .navigationTitle("Scan Barcode")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

private struct AddItemDatesSection: View {
    @Binding var purchaseDate: Date
    @Binding var expirationDate: Date

    var body: some View {
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
    }
}

private struct AddItemNotificationSection: View {
    @Binding var sendNotification: Bool
    @Binding var notificationTime: Int

    var body: some View {
        Section("Reminder") {
            Toggle("Enable Notification", isOn: $sendNotification)
                .tint(Color.sproutGreen)

            if sendNotification {
                Picker("Notify Me", selection: $notificationTime) {
                    ForEach(1...5, id: \.self) { day in
                        Text(day == 1 ? "1 day before" : "\(day) days before")
                            .tag(day)
                    }
                }
                .pickerStyle(.navigationLink)
            }
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
