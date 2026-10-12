//
//  BarcodeNormalizerTests.swift
//  Grocery TrackerTests
//

import Testing

@testable import Grocery_Tracker

struct BarcodeNormalizerTests {
    static var cases: [(String, String)] {
        [
            ("12345670", "12345670"),
            ("012345678905", "012345678905"),
            ("0 12345-67890 5", "012345678905"),
            ("0012345678905", "0012345678905"),
            ("00012345678905", "00012345678905")
        ]
    }

    @Test(arguments: cases)
    func `Barcode normalization preserves leading zeroes`(
        input: (String, String)
    ) throws {
        #expect(try BarcodeNormalizer.normalize(input.0) == input.1)
    }

    @Test
    func `Letters are rejected`() {
        #expect(throws: BarcodeNormalizationError.invalidCode) {
            try BarcodeNormalizer.normalize("01234ABC8905")
        }
    }

    @Test
    func `Unsupported lengths are rejected`() {
        #expect(throws: BarcodeNormalizationError.invalidCode) {
            try BarcodeNormalizer.normalize("1234567")
        }
    }
}
