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
}
