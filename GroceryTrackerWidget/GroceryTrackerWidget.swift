//
//  GroceryTrackerWidget.swift
//  GroceryTrackerWidget
//

import SwiftUI
import WidgetKit

private enum WidgetSharedData {
    static let appGroupIdentifier = "group.SproutsGroceryTracker"
    static let snapshotKey = "activeGroceryWidgetItems"
}

private struct WidgetGroceryItem: Codable, Sendable {
    let id: String
    let name: String
    let inventorySummary: String
    let expirationDate: Date
}

private struct GroceryWidgetEntry: TimelineEntry {
    let date: Date
    let items: [WidgetGroceryItem]
}

private struct GroceryWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> GroceryWidgetEntry {
        GroceryWidgetEntry(date: .now, items: Self.sampleItems)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (GroceryWidgetEntry) -> Void
    ) {
        completion(
            GroceryWidgetEntry(
                date: .now,
                items: context.isPreview ? Self.sampleItems : loadItems()
            )
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<GroceryWidgetEntry>) -> Void
    ) {
        let now = Date()
        let entry = GroceryWidgetEntry(date: now, items: loadItems())
        let nextRefresh = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Calendar.current.startOfDay(for: now)
        ) ?? now.addingTimeInterval(60 * 60 * 6)

        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadItems() -> [WidgetGroceryItem] {
        guard let data = UserDefaults(
            suiteName: WidgetSharedData.appGroupIdentifier
        )?.data(forKey: WidgetSharedData.snapshotKey) else {
            return []
        }

        return (try? JSONDecoder().decode([WidgetGroceryItem].self, from: data)) ?? []
    }

    private static let sampleItems = [
        WidgetGroceryItem(
            id: "sample-milk",
            name: "Whole Milk",
            inventorySummary: "1 gallon",
            expirationDate: .now
        ),
        WidgetGroceryItem(
            id: "sample-spinach",
            name: "Fresh Spinach",
            inventorySummary: "2 × 5 oz",
            expirationDate: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now
        ),
        WidgetGroceryItem(
            id: "sample-yogurt",
            name: "Greek Yogurt",
            inventorySummary: "4 packages",
            expirationDate: Calendar.current.date(byAdding: .day, value: 5, to: .now) ?? .now
        )
    ]
}

private struct GroceryTrackerWidgetView: View {
    @Environment(\.widgetFamily) private var widgetFamily

    let entry: GroceryWidgetEntry

    var body: some View {
        Group {
            if entry.items.isEmpty {
                WidgetEmptyView()
            } else if widgetFamily == .systemMedium {
                MediumExpirationView(items: Array(entry.items.prefix(3)))
            } else {
                SmallExpirationView(item: entry.items[0])
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

private struct SmallExpirationView: View {
    let item: WidgetGroceryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Next to Expire", systemImage: "leaf.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.sproutWidgetGreen)

            Spacer(minLength: 0)

            Text(item.name)
                .font(.headline)
                .lineLimit(2)

            Text(item.inventorySummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            ExpirationBadge(expirationDate: item.expirationDate)
        }
    }
}

private struct MediumExpirationView: View {
    let items: [WidgetGroceryItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Expiring Groceries", systemImage: "leaf.fill")
                .font(.headline)
                .foregroundStyle(Color.sproutWidgetGreen)

            ForEach(items, id: \.id) { item in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(item.inventorySummary)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    ExpirationBadge(expirationDate: item.expirationDate)
                }
            }

            Spacer(minLength: 0)
        }
    }
}

private struct ExpirationBadge: View {
    let expirationDate: Date

    var body: some View {
        Label(expirationText, systemImage: expirationSymbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(expirationColor)
            .lineLimit(1)
    }

    private var dayDifference: Int {
        Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: expirationDate)
        ).day ?? 0
    }

    private var expirationText: String {
        switch dayDifference {
        case ..<0:
            "Expired"
        case 0:
            "Today"
        case 1:
            "Tomorrow"
        default:
            "In \(dayDifference) days"
        }
    }

    private var expirationSymbol: String {
        dayDifference < 0 ? "exclamationmark.triangle.fill" : "calendar"
    }

    private var expirationColor: Color {
        dayDifference <= 1 ? .orange : .secondary
    }
}

private struct WidgetEmptyView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Groceries", systemImage: "basket")
        } description: {
            Text("Add groceries in Sprouts to see upcoming expirations.")
        }
    }
}

private extension Color {
    static let sproutWidgetGreen = Color(
        red: 52 / 255,
        green: 168 / 255,
        blue: 83 / 255
    )
}

struct GroceryTrackerWidget: Widget {
    let kind = "GroceryTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GroceryWidgetProvider()) { entry in
            GroceryTrackerWidgetView(entry: entry)
        }
        .configurationDisplayName("Expiring Groceries")
        .description("See which groceries expire next.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview("Small", as: .systemSmall) {
    GroceryTrackerWidget()
} timeline: {
    GroceryWidgetEntry(
        date: .now,
        items: [
            WidgetGroceryItem(
                id: "preview-milk",
                name: "Whole Milk",
                inventorySummary: "1 gallon",
                expirationDate: .now
            )
        ]
    )
}

#Preview("Medium", as: .systemMedium) {
    GroceryTrackerWidget()
} timeline: {
    GroceryWidgetEntry(
        date: .now,
        items: [
            WidgetGroceryItem(
                id: "preview-milk",
                name: "Whole Milk",
                inventorySummary: "1 gallon",
                expirationDate: .now
            ),
            WidgetGroceryItem(
                id: "preview-spinach",
                name: "Fresh Spinach",
                inventorySummary: "2 × 5 oz",
                expirationDate: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now
            ),
            WidgetGroceryItem(
                id: "preview-yogurt",
                name: "Greek Yogurt",
                inventorySummary: "4 packages",
                expirationDate: Calendar.current.date(byAdding: .day, value: 5, to: .now) ?? .now
            )
        ]
    )
}
