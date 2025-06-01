import SwiftUI

struct SproutsHeader: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "leaf")
                .font(.title2)
                .foregroundColor(.sproutGreen)

            Text("Sprouts")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.sproutGreen)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
    }
}
