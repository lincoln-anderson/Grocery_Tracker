//  GroceryItemGridView.swift
//  Grocery_Tracker

import SwiftUI

struct GroceryItemGridCard: View {

    @Environment(\.colorScheme) var colorScheme

    @ObservedObject var item: GroceryItem

    var containerWidth: CGFloat = UIScreen.main.bounds.width - 32.0

    var body: some View {

        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.headline)
                    .bold()
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(width: containerWidth / 3, height: 52, alignment: .leading)

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(.sproutGreen)
                    Text(item.expirationDate?.shortDisplayString ?? "")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "scalemass")
                        .foregroundColor(.sproutGreen)
                    Text("\(item.quantity) \(item.measurement ?? "")")
                        .font(.footnote)
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
}

struct GroceryItemGridView_Previews: PreviewProvider {
    static var viewContext = PersistenceController.preview.container.viewContext

    static var previews: some View {
        let item = {
            let i = GroceryItem(context: viewContext)
            i.expirationDate = Date()
            i.name = "Canned Beans"
            i.quantity = 2
            i.measurement = "cans"
            return i
        }()

        return VStack(spacing: 16) {
            GroceryItemGridCard(item: item)
                .environment(\.managedObjectContext, viewContext)
        }
        .previewLayout(.sizeThatFits)
    }

}
