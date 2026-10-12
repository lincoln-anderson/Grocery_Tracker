//
//  SectionHeader.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 5/31/25.
//

import SwiftUI

struct SectionHeader: View {
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)

            Text(text)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .accessibilityAddTraits(.isHeader)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
