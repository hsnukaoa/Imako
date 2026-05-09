//
//  QrCodeView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/05/02.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

struct QrCodeView: View {
    var data: String
    
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
                
                if let pdfURL = generatePDF(from: image) {
                    ShareLink(item: pdfURL) {
                        Label("PDFとして共有", systemImage: "square.and.arrow.up")
                    }
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
    
    private func generatePDF(from image: UIImage) -> URL? {
        let format = UIGraphicsPDFRendererFormat()
        let bounds = CGRect(origin: .zero, size: image.size)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("QRCode.pdf")
        
        do {
            try renderer.writePDF(to: tempURL) { context in
                context.beginPage()
                image.draw(in: bounds)
            }
            return tempURL
        } catch {
            print("PDFの生成に失敗しました: \(error)")
            return nil
        }
    }
}

#Preview {
    QrCodeView(data: "abc")
        .frame(width: 150, height: 150)
}
