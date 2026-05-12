//
//  QRCodeScanner.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/05/11.
//

import SwiftUI
import VisionKit
import Vision
import FirebaseFirestore

struct QRCodeScanner: UIViewControllerRepresentable {
    var onResult: (Item) -> Void
    
    private let db = Firestore.firestore()
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let dataScannerViewController = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            isHighlightingEnabled: true
        )
        dataScannerViewController.delegate = context.coordinator
        try? dataScannerViewController.startScanning()
        return dataScannerViewController
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let parent: QRCodeScanner
        private var isFetching = false
        
        init(_ qrCodeScanner: QRCodeScanner) {
            self.parent = qrCodeScanner
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !isFetching, case .barcode(let barcode) = addedItems.first else {
                return
            }
            
            if let payloadStringValue = barcode.payloadStringValue {
                isFetching = true
                
                Task { @MainActor in
                    defer { self.isFetching = false }
                    
                    do {
                        let snapshot = try await parent.db.collection("items")
                            .whereField("id", isEqualTo: payloadStringValue)
                            .getDocuments()
                        
                        if let document = snapshot.documents.first {
                            if let fetchedItem = try? document.data(as: Item.self) {
                                self.parent.onResult(fetchedItem)
                            } else {
                                print("Item型へのデコードに失敗しました")
                            }
                        }
                    } catch {
                        print("データの取得に失敗しました: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        }
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
    }
}
