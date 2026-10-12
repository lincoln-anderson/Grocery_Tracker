//
//  BarcodeScannerView.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 6/2/25.
//

import SwiftUI
import Vision
import VisionKit

enum BarcodeScannerError: Error, Identifiable {
    case unsupported
    case cameraUnavailable
    case invalidBarcode
    case scanningFailed

    var id: Self { self }
}

struct BarcodeScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    let onError: (BarcodeScannerError) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [
                .barcode(
                    symbologies: [
                        .ean8,
                        .ean13,
                        .upce,
                        .gs1DataBar,
                        .gs1DataBarExpanded,
                        .gs1DataBarLimited
                    ]
                )
            ],
            qualityLevel: .accurate,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )

        scanner.delegate = context.coordinator

        guard DataScannerViewController.isSupported else {
            onError(.unsupported)
            return scanner
        }

        guard DataScannerViewController.isAvailable else {
            onError(.cameraUnavailable)
            return scanner
        }

        do {
            try scanner.startScanning()
        } catch {
            onError(.scanningFailed)
        }

        return scanner
    }

    func updateUIViewController(
        _ uiViewController: DataScannerViewController,
        context: Context
    ) {}

    static func dismantleUIViewController(
        _ uiViewController: DataScannerViewController,
        coordinator: Coordinator
    ) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onError: onError)
    }

    @MainActor
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onScan: (String) -> Void
        private let onError: (BarcodeScannerError) -> Void
        private var hasCompletedScan = false

        init(
            onScan: @escaping (String) -> Void,
            onError: @escaping (BarcodeScannerError) -> Void
        ) {
            self.onScan = onScan
            self.onError = onError
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didTapOn item: RecognizedItem
        ) {
            guard !hasCompletedScan,
                  case let .barcode(barcode) = item,
                  let payload = barcode.payloadStringValue else {
                return
            }

            do {
                let normalizedCode = try BarcodeNormalizer.normalize(payload)
                hasCompletedScan = true
                dataScanner.stopScanning()
                onScan(normalizedCode)
            } catch {
                onError(.invalidBarcode)
            }
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable
        ) {
            dataScanner.stopScanning()
            onError(.cameraUnavailable)
        }
    }
}
