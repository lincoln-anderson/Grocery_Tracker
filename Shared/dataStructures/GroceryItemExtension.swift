//
//  GroceryItemExtension.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 6/13/25.
//

import Foundation
import SwiftUI



extension GroceryItem {
    var displayName: String {
        let name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (name?.isEmpty ?? true) ? "Unnamed" : name!.capitalized
    }

    /// New records use `quantity` as a package count. Older records stored the
    /// numeric product size there and can be identified by their measurement.
    var packageCount: Int {
        packageSize?.nilIfBlank == nil && measurement?.nilIfBlank != nil
            ? 1
            : max(Int(quantity), 1)
    }

    var displayPackageSize: String? {
        if let packageSize = packageSize?.nilIfBlank {
            return packageSize
        }

        guard let measurement = measurement?.nilIfBlank, quantity > 0 else {
            return nil
        }

        return "\(quantity) \(measurement)"
    }

    var inventorySummary: String {
        guard let displayPackageSize else {
            return packageCount == 1 ? "1 package" : "\(packageCount) packages"
        }

        return packageCount == 1
            ? displayPackageSize
            : "\(packageCount) × \(displayPackageSize)"
    }
}
