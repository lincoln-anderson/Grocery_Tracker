//  GroceryItemGridView.swift
//  Grocery_Tracker

import SwiftUI

enum GroceryItemCardStyle {
    case list
    case grid
}

struct GroceryItemGridCard: View {
    @ScaledMetric(relativeTo: .body) private var thumbnailSize: CGFloat = 56

    @ObservedObject var item: GroceryItem
    var style = GroceryItemCardStyle.grid

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            GroceryItemThumbnail(
                imageURL: item.imageURL.flatMap(URL.init(string:)),
                size: thumbnailSize
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(item.displayName)
                    .font(.headline.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                if let brand = item.brand?.nilIfBlank {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(item.inventorySummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Label(expirationSummary, systemImage: "calendar")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(expirationColor)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 64)
        .padding(style == .grid ? 16 : 0)
        .background(
            style == .grid
                ? AnyShapeStyle(Color(.secondarySystemGroupedBackground))
                : AnyShapeStyle(.clear)
        )
        .clipShape(.rect(cornerRadius: 12))
        .shadow(
            color: style == .grid ? .black.opacity(0.08) : .clear,
            radius: 4,
            y: 2
        )
        .accessibilityElement(children: .combine)
    }

    private var expirationSummary: String {
        guard let date = item.expirationDate else { return "No expiration date" }

        if date.isExpired {
            return "Expired \(date.shortDisplayString)"
        }
        if date.isToday {
            return "Expires today"
        }
        if date.isTomorrow {
            return "Expires tomorrow"
        }
        return "Expires \(date.shortDisplayString)"
    }

    private var expirationColor: Color {
        guard let date = item.expirationDate else { return .secondary }

        if date.isExpired {
            return .red
        }
        if date.isToday || date.isTomorrow || date.isWithin(days: 7) {
            return .orange
        }
        return .secondary
    }
}

private struct GroceryItemThumbnail: View {
    let imageURL: URL?
    let size: CGFloat

    var body: some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    thumbnailPlaceholder
                }
            } else {
                thumbnailPlaceholder
            }
        }
        .frame(width: size, height: size)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityHidden(true)
    }

    private var thumbnailPlaceholder: some View {
        Image(systemName: "leaf")
            .font(.title2)
            .foregroundStyle(Color.sproutGreen)
    }
}

#Preview("Grocery Item Card") {
    let context = PersistenceController.preview.container.viewContext
    let item = GroceryItem(context: context)
    item.expirationDate = .now
    item.name = "Canned Beans"
    item.quantity = 2
    item.packageSize = "15 oz"

    return GroceryItemGridCard(item: item, style: .grid)
        .environment(\.managedObjectContext, context)
        .padding(.vertical)
}
