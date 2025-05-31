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
            HStack(spacing: 6) {
                Text(text)
                    .font(.headline)
                    .foregroundColor(color)
            }
        .padding(.horizontal, 20)
            .frame(maxWidth: .infinity ,alignment: .leading)
        }
}
