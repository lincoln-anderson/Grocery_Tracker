//
//  EditItemView.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 6/21/25.
//

import SwiftUI

struct EditItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var item: GroceryItem
    @Binding var isPresented: Bool

    @State private var name: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var expirationDate: Date = Date()
    @State private var quantity: String = ""
    @State private var measurement: String = "Oz"

    enum Measurements: String, CaseIterable, Identifiable {
        case oz, lb, ml
        var id: String { self.rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Edit Grocery Item")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.sproutGreen)
                    .padding(.top)

                Divider()

                TextField("Item Name", text: $name)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                HStack {
                    VStack(alignment: .leading) {
                        Text("Purchase Date")
                            .font(.caption)
                            .foregroundColor(.sproutGreen)
                        DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                            .labelsHidden()
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    Spacer()

                    VStack(alignment: .leading) {
                        Text("Expiration Date")
                            .font(.caption)
                            .foregroundColor(.sproutGreen)
                        DatePicker("", selection: $expirationDate, displayedComponents: .date)
                            .labelsHidden()
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                }

                VStack(alignment: .leading) {
                    Text("Quantity & Measurement")
                        .font(.caption)
                        .foregroundColor(.sproutGreen)

                    HStack {
                        TextField("Item weight", text: $quantity)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .keyboardType(.decimalPad)
                            .onChange(of: quantity) { newValue in
                                let filtered = newValue.filter { "0123456789.".contains($0) }
                                // Only allow one period
                                let parts = filtered.split(separator: ".", omittingEmptySubsequences: false)
                                if parts.count <= 2 {
                                    quantity = parts.joined(separator: ".")
                                } else {
                                    quantity = parts[0] + "." + parts[1]
                                }
                            }

                        Picker("Measurement", selection: $measurement) {
                            ForEach(Measurements.allCases) { Text($0.rawValue.capitalized) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 100)
                }

                Button("Save Changes") {
                    updateItem()
                    isPresented = false
                }
                .buttonStyle(SproutsButtonStyle(color: .green))
            }
            .padding()
            .onAppear {
                loadItem()
            }
        }
    }

    private func loadItem() {
        name = item.name ?? ""
        purchaseDate = item.purchasedDate ?? Date()
        expirationDate = item.expirationDate ?? Date()
        quantity = String(item.quantity)
        measurement = item.measurement ?? "Oz"
    }

    private func updateItem() {
        item.name = name
        item.purchasedDate = purchaseDate
        item.expirationDate = expirationDate
        item.quantity = Double(quantity) ?? 1
        item.measurement = measurement

        do {
            try viewContext.save()
        } catch {
            print("Error saving item: \(error.localizedDescription)")
        }
    }
}
