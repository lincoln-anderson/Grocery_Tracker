//
//  ProductLookupServiceTests.swift
//  Grocery TrackerTests
//

import Foundation
import Testing

@testable import Grocery_Tracker

struct ProductLookupServiceTests {
    @Test
    func `Open Food Facts product is decoded`() throws {
        let data = Data(
            """
            {
              "product": {
                "code": "0034000470693",
                "product_name": "Chocolate Hazelnut Spread",
                "brands": "Example Brand",
                "quantity": "13 oz",
                "image_front_small_url": "https://images.openfoodfacts.org/product.jpg"
              }
            }
            """.utf8
        )

        let product = try OpenFoodFactsProductLookupService.decodeProduct(
            from: data
        )

        #expect(product.barcode == "0034000470693")
        #expect(product.name == "Chocolate Hazelnut Spread")
        #expect(product.brand == "Example Brand")
        #expect(product.quantity == "13 oz")
        #expect(product.imageURL == URL(string: "https://images.openfoodfacts.org/product.jpg"))
    }

    @Test
    func `Generic name is used when product name is missing`() throws {
        let data = Data(
            """
            {
              "product": {
                "code": "12345670",
                "generic_name": "Sparkling Water"
              }
            }
            """.utf8
        )

        let product = try OpenFoodFactsProductLookupService.decodeProduct(
            from: data
        )

        #expect(product.name == "Sparkling Water")
    }

    @Test
    func `Missing product is reported as not found`() {
        let data = Data(#"{"status":"failure"}"#.utf8)

        #expect(throws: ProductLookupError.productNotFound) {
            try OpenFoodFactsProductLookupService.decodeProduct(from: data)
        }
    }

    @Test
    func `Product without a usable name is rejected`() {
        let data = Data(
            """
            {
              "product": {
                "code": "12345670",
                "product_name": "   "
              }
            }
            """.utf8
        )

        #expect(throws: ProductLookupError.missingProductName) {
            try OpenFoodFactsProductLookupService.decodeProduct(from: data)
        }
    }
}
