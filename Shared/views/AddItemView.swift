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
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    Spacer(minLength: 0)

                    VStack(spacing: 20) {
                        AddItemHeader()

                        AddItemNameSection(name: $newName)

                        AddItemBarcodeSection(
                            barcode: Binding(
                                get: { barcode },
                                set: { value in
                                    barcode = value
                                    productLookupState = .idle
                                    productImageURL = nil
                                }
                            ),
                            lookupState: productLookupState,
                            scanAction: { showingScanner = true },
                            lookupAction: {
                                Task {
                                    await lookupProduct(barcode)
                                }
                            }
                        )

                        AddItemProductDetailsSection(
                            brand: $brand,
                            packageSize: $packageSize,
                            packageCount: $quantity,
                            imageURL: productImageURL
                        )

                        AddItemDatesSection(
                            purchaseDate: $purchaseDate,
                            expirationDate: $expirationDate
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

        do {
            try newItem(
                newName: validatedName,
                expirationDate: expirationDate,
                purchaseDate: purchaseDate,
                quantity: Int16(quantity),
                barcode: barcode,
                brand: brand,
                packageSize: packageSize,
                imageURL: productImageURL
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
        barcode: String,
        brand: String,
        packageSize: String,
        imageURL: URL?
    ) throws {
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

        do {
            try viewContext.save()
        } catch {
            viewContext.delete(newItem)
            throw error
        }
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

private struct AddItemBarcodeSection: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Binding var barcode: String
    let lookupState: ProductLookupState
    let scanAction: () -> Void
    let lookupAction: () -> Void

    var body: some View {
        let buttonLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))

        LabeledField(title: "Barcode (Optional)") {
            TextField("Enter barcode digits", text: $barcode)
                .keyboardType(.numberPad)
                .textContentType(.none)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(.rect(cornerRadius: 10))

            buttonLayout {
                Button(action: scanAction) {
                    Label("Scan Barcode", systemImage: "barcode.viewfinder")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.sproutGreen)

                Button(action: lookupAction) {
                    Label("Look Up Product", systemImage: "magnifyingglass")
                }
                .buttonStyle(.bordered)
                .disabled(
                    barcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || lookupState == .loading
                )
            }

            ProductLookupStatusView(state: lookupState)
        }
        .padding(.horizontal)
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

private struct AddItemProductDetailsSection: View {
    @Binding var brand: String
    @Binding var packageSize: String
    @Binding var packageCount: Int
    let imageURL: URL?

    var body: some View {
        LabeledField(title: "Package Details") {
            if let imageURL {
                ProductImageView(url: imageURL)
                    .frame(maxWidth: .infinity)
            }

            TextField("Brand", text: $brand)
                .textContentType(.organizationName)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(.rect(cornerRadius: 10))

            TextField("Package size (for example, 12 oz)", text: $packageSize)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(.rect(cornerRadius: 10))

            Stepper(value: $packageCount, in: 1...100) {
                LabeledContent("Number of Packages", value: "\(packageCount)")
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(.rect(cornerRadius: 10))

            Text(inventorySummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Inventory total: \(inventorySummary)")
        }
        .padding(.horizontal)
    }

    private var inventorySummary: String {
        guard let size = packageSize.nilIfBlank else {
            return packageCount == 1 ? "1 package" : "\(packageCount) packages"
        }

        return packageCount == 1 ? size : "\(packageCount) × \(size)"
    }
}

struct ProductImageView: View {
    let url: URL

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
        .frame(height: 140)
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
