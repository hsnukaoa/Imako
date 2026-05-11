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
    @Binding var  recognizedPayload: String
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
    
    final class Coordinator: NSObject, DataScannerViewControllerDelegate{
        private let parent: QRCodeScanner
        
        init(_ qrCodeScanner: QRCodeScanner) {
            self.parent = qrCodeScanner
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard case .barcode(let barcode) = addedItems.first else {
                return
            }
            
            if let payloadStringValue = barcode.payloadStringValue {
                parent.db.collection("items").whereField("id", isEqualTo: payloadStringValue).getDocuments { snapshot, _ in
                    
                    if let document = snapshot?.documents.first {
                        let item = document
                        
                        // UIの更新を伴うためメインスレッドで実行
                        DispatchQueue.main.async {
                            self.parent.recognizedPayload = payloadStringValue
                        }
                    }
                }
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            parent.recognizedPayload = ""
        }
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
    }
}

