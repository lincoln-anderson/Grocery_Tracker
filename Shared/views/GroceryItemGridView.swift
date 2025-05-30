//  GroceryItemGridView.swift
//  Grocery_Tracker

import SwiftUI

struct GroceryItemGridView: View {

    @Environment(\.colorScheme) var colorScheme

    var item: GroceryItem

    var containerWidth: CGFloat = UIScreen.main.bounds.width - 32.0

    let sproutGreen = Color(red: 0.32, green: 0.55, blue: 0.39) // A nice brussel sprout green

    var body: some View {

        HStack(alignment: .top, spacing: 12) {

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name ?? "Unnamed")
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(sproutGreen)
                    Text(item.expirationDate?.shortDisplayString ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "scalemass")
                        .foregroundColor(sproutGreen)
                    Text("\(item.quantity) \(item.measurement ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }

    private func initials(from name: String?) -> String {
        guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return "--" }
        let parts = name.components(separatedBy: " ")
        let initials = parts.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }
}

struct GroceryItemGridView_Previews: PreviewProvider {
    static var viewContext = PersistenceController.preview.container.viewContext

    static var previews: some View {
        let item = GroceryItem(context: viewContext)
        item.expirationDate = Date()
        item.name = "Canned Beans"
        item.quantity = 2
        item.measurement = "cans"

        return GroceryItemGridView(item: item)
            .environment(\.managedObjectContext, viewContext)
            .previewLayout(.sizeThatFits)
    }
}
