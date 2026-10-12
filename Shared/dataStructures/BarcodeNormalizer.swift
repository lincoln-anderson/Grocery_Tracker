//
//  BarcodeNormalizer.swift
//  Grocery Tracker
//

import Foundation

enum BarcodeNormalizationError: Error, Equatable {
    case invalidCode
}

struct BarcodeNormalizer {
    static func normalize(_ value: String) throws -> String {
        let digits = value.filter(\.isNumber)

        guard [8, 12, 13, 14].contains(digits.count),
              value.allSatisfy({ $0.isNumber || $0.isWhitespace || $0 == "-" }) else {
            throw BarcodeNormalizationError.invalidCode
        }

        return digits
    }
}
