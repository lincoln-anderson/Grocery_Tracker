//
//  Theme.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 5/31/25.
//

import SwiftUI
import UIKit

extension Color {
    public static let sproutGreen = Color(
        uiColor: UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(red: 0.40, green: 0.70, blue: 0.48, alpha: 1)
            }

            return UIColor(red: 0.24, green: 0.46, blue: 0.31, alpha: 1)
        }
    )
}
