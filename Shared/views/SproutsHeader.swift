import SwiftUI

struct SproutsHeader: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "leaf")
                .font(.title2)
                .foregroundStyle(Color.sproutGreen)
                .accessibilityHidden(true)

            Text("Sprouts")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.sproutGreen)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
