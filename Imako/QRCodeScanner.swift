import SwiftUI
import VisionKit
import Vision
import FirebaseFirestore

struct QRCodeScanner: UIViewControllerRepresentable {
    @Binding var isScanning: Bool
    var onResult: (Item) -> Void
    
    private let db = Firestore.firestore()
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let dataScannerViewController = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            isHighlightingEnabled: true
        )
        dataScannerViewController.delegate = context.coordinator
        return dataScannerViewController
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if isScanning {
            if !uiViewController.isScanning {
                try? uiViewController.startScanning()
            }
        } else {
            if uiViewController.isScanning {
                uiViewController.stopScanning()
            }
        }
    }
    
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let parent: QRCodeScanner
        private var isFetching = false
        
        init(_ qrCodeScanner: QRCodeScanner) {
            self.parent = qrCodeScanner
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !isFetching, case .barcode(let barcode) = addedItems.first else { return }
            
            if let payloadStringValue = barcode.payloadStringValue {
                isFetching = true
                
                Task { @MainActor in
                    defer { self.isFetching = false }
                    
                    do {
                        let documentRef = parent.db.collection("items").document(payloadStringValue)
                        let document = try await documentRef.getDocument()
                        
                        if document.exists {
                            do {
                                let fetchedItem = try document.data(as: Item.self)
                                self.parent.onResult(fetchedItem)
                            } catch {
                            }
                        }
                    } catch {
                    }
                }
            }
        }
    }
}
