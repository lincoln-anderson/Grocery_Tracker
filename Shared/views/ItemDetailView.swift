//
//  ItemDetailView.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 6/13/25.
//

import SwiftUI

struct ItemDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State var isEditing: Bool = false
    @State private var showEditSheet = false
    @State var itemName: String = ""
    
    @ObservedObject var item: GroceryItem
    
    var daysUntilExpiration: String {
        guard let expiration = item.expirationDate else { return "N/A" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day ?? 0
        if days < 0 {
            return "Expired"
        } else if days == 0 {
            return "Expires Today"
        } else if days == 1 {
            return "1 day"
        } else {
            return "\(days) days"
        }
    }
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Grocery Item Details")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.sproutGreen)
                        .padding(.top)
                    
                    Divider()
                    
                    // Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Item Name")
                            .font(.caption)
                            .foregroundColor(.sproutGreen)
                        if isEditing {
                            TextField("", text: $itemName)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        Text(item.displayName)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Dates
                    
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Purchase Date")
                                .font(.caption)
                                .foregroundColor(.sproutGreen)
                            Text(item.purchasedDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Expiration Date")
                                .font(.caption)
                                .foregroundColor(.sproutGreen)
                            Text(item.expirationDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Days Until Expiration")
                                .font(.caption)
                                .foregroundColor(.sproutGreen)
                            
                            Text(daysUntilExpiration)
                                .italic()
                                .padding()
                                .foregroundColor(daysUntilExpiration == "Expired" ? .red : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)

                            
                            
                        }
                        
                        
                    }
                    
                    // Quantity & Measurement
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quantity & Measurement")
                            .font(.caption)
                            .foregroundColor(.sproutGreen)
                        Text("\(item.quantity) \(item.measurement ?? "")")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(item.displayName)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showEditSheet = true
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditItemView(item: item, isPresented: $showEditSheet)
            }
        }
    }
}
