//
//  BarcodeScannerView.swift
//  Grocery Tracker
//
//  Created by lincoln anderson on 6/2/25.
//

import SwiftUI
import VisionKit
import Vision

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var ScannedCode: String?
    @Environment(\.dismiss) var dismiss
    
    @available(iOS 16.0, *)
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .upce])],
            qualityLevel: .accurate,
            isHighlightingEnabled: true
        )
        
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}
        
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
        }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: BarcodeScannerView
        
        init(parent: BarcodeScannerView) {
            self.parent = parent
        }
        
        func dataScanner(_ scanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            if case let .barcode(barcode) = item {
                parent.ScannedCode = barcode.payloadStringValue
                parent.dismiss()
            }
        }
    }
}
