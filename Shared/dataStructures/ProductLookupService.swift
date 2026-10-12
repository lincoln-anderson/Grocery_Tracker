//
//  ProductLookupService.swift
//  Grocery Tracker
//

import Foundation

struct ProductLookupResult: Equatable, Sendable {
    let barcode: String
    let name: String
    let brand: String?
    let quantity: String?
    let imageURL: URL?
}

enum ProductLookupError: Error, Equatable {
    case invalidResponse
    case productNotFound
    case missingProductName
}

protocol ProductLookupService: Sendable {
    func product(for barcode: String) async throws -> ProductLookupResult
}

struct OpenFoodFactsProductLookupService: ProductLookupService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func product(for barcode: String) async throws -> ProductLookupResult {
        let normalizedBarcode = try BarcodeNormalizer.normalize(barcode)
        let url = try productURL(for: normalizedBarcode)

        var request = URLRequest(url: url)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProductLookupError.invalidResponse
        }

        if httpResponse.statusCode == 404 {
            throw ProductLookupError.productNotFound
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ProductLookupError.invalidResponse
        }

        return try Self.decodeProduct(from: data)
    }

    static func decodeProduct(from data: Data) throws -> ProductLookupResult {
        let response = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)

        guard let product = response.product else {
            throw ProductLookupError.productNotFound
        }

        let candidateNames = [
            product.productName,
            product.abbreviatedProductName,
            product.genericName
        ]
        let name = candidateNames
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }

        guard let name else {
            throw ProductLookupError.missingProductName
        }

        return ProductLookupResult(
            barcode: product.code ?? "",
            name: name,
            brand: product.brands?.nilIfBlank,
            quantity: product.quantity?.nilIfBlank,
            imageURL: product.imageFrontSmallURL.flatMap(URL.init(string:))
        )
    }

    private func productURL(for barcode: String) throws -> URL {
        var components = URLComponents(
            string: "https://world.openfoodfacts.org/api/v3/product/\(barcode)"
        )
        components?.queryItems = [
            URLQueryItem(
                name: "fields",
                value: "code,product_name,abbreviated_product_name,generic_name,brands,quantity,image_front_small_url"
            ),
            URLQueryItem(name: "product_type", value: "food")
        ]

        guard let url = components?.url else {
            throw ProductLookupError.invalidResponse
        }

        return url
    }

    private static var userAgent: String {
        let bundle = Bundle.main
        let version = bundle.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "unknown"
        let identifier = bundle.bundleIdentifier ?? "unknown.bundle"

        return "SproutsGroceryTracker/\(version) (\(identifier))"
    }
}

private struct OpenFoodFactsResponse: Decodable {
    let product: Product?

    struct Product: Decodable {
        let code: String?
        let productName: String?
        let abbreviatedProductName: String?
        let genericName: String?
        let brands: String?
        let quantity: String?
        let imageFrontSmallURL: String?

        enum CodingKeys: String, CodingKey {
            case code
            case productName = "product_name"
            case abbreviatedProductName = "abbreviated_product_name"
            case genericName = "generic_name"
            case brands
            case quantity
            case imageFrontSmallURL = "image_front_small_url"
        }
    }
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
