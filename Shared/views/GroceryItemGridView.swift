//  GroceryItemGridView.swift
//  Grocery_Tracker

import SwiftUI

struct GroceryItemGridView: View {

    @Environment(\.colorScheme) var colorScheme

    var item: GroceryItem

    var containerWidth: CGFloat = UIScreen.main.bounds.width - 32.0

    var body: some View {
//        let isFresh = item.expirationDate?.isExpired == false || item.expirationDate?.isSameDay(as: Date()) == true

        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name?.capitalized ?? "Unnamed")
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(.sproutGreen)
                    Text(item.expirationDate?.shortDisplayString ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "scalemass")
                        .foregroundColor(.sproutGreen)
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
}

struct SproutsButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.sproutGreen)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.05 : 0.1), radius: 2, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
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
            GroceryItemGridView(item: item)
                .environment(\.managedObjectContext, viewContext)

            Button("Add Item") {}
                .buttonStyle(SproutsButtonStyle(color: .green))

            Button("Mark Item as Used") {}
                .buttonStyle(SproutsButtonStyle(color: .green))
        }
        .previewLayout(.sizeThatFits)
    }

}
