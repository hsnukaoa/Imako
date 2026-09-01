//
//  QrCodeView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/05/02.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

// 用紙サイズの定義 (1mm = 約2.83465pt)
enum PaperSize: String, CaseIterable, Identifiable {
    case a4 = "A4"
    case a3 = "A3"
    case b3 = "B3"
    case stickerL = "L判(シール)"
    
    var id: String { self.rawValue }
    
    var sizeInPoints: CGSize {
        switch self {
        case .a3: return CGSize(width: 841.89, height: 1190.55) // 297 x 420 mm
        case .a4: return CGSize(width: 595.28, height: 841.89)  // 210 x 297 mm
        case .b3: return CGSize(width: 1031.8, height: 1459.8)  // JIS B3 364 x 515 mm
        case .stickerL: return CGSize(width: 252.28, height: 360.0) // L判 89 x 127 mm
        }
    }
}

struct QrCodeView: View {
    var item: Item?
    @State private var data: String
    
    init(item: Item) {
        self.item = item
        self._data = State(initialValue: String(item.id!))
    }
    
    init(data: String) {
        self.item = nil
        self._data = State(initialValue: data)
    }
    
    var body: some View {
        let image = qrImage
        
        Image(uiImage: image)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .accessibilityLabel(Text("QRCode"))
            .contextMenu {
                Button {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                } label: {
                    Label("写真に保存", systemImage: "photo.badge.arrow.down")
                }
                
                Menu {
                    ForEach(PaperSize.allCases) { paper in
                        if let pdfURL = generatePDF(from: image, paperSize: paper) {
                            ShareLink(item: pdfURL) {
                                Text("\(paper.rawValue)サイズ")
                            }
                        }
                    }
                } label: {
                    Label("PDFで共有 (2cm角で印刷)", systemImage: "square.and.arrow.up")
                }
            }
    }
    
    private var qrImage: UIImage {
        let qrCodeGenerator = CIFilter.qrCodeGenerator()
        qrCodeGenerator.message = Data(data.utf8)
        qrCodeGenerator.correctionLevel = "H"
        
        guard let outputImage = qrCodeGenerator.outputImage else {
            return UIImage()
        }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        if let cgImage = CIContext().createCGImage(scaledImage, from: scaledImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return UIImage()
    }
    
    private func generatePDF(from image: UIImage, paperSize: PaperSize) -> URL? {
        let format = UIGraphicsPDFRendererFormat()
        let bounds = CGRect(origin: .zero, size: paperSize.sizeInPoints)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(item?.name ?? "QRCode")_\(paperSize.rawValue).pdf")
        
        do {
            try renderer.writePDF(to: tempURL) { context in
                context.beginPage()
                
                // 1mm = 2.83465pt
                let qrSizeInPoints: CGFloat = 20.0 * 2.83465
                let marginInPoints: CGFloat = 15.0 * 2.83465
                
                let drawRect = CGRect(x: marginInPoints, y: marginInPoints, width: qrSizeInPoints, height: qrSizeInPoints)
                
                image.draw(in: drawRect)
            }
            return tempURL
        } catch {
            return nil
        }
    }
}
