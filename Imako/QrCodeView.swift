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
        Image(uiImage: qrImage)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .accessibilityLabel(Text("QRCode"))
            .contextMenu {
                Button {
                    // Add this item to a list of favorites.
                } label: {
                    Label("写真に保存", systemImage: "photo.badge.arrow.down")
                }
                Button {
                    // Open Maps and center it on this item.
                } label: {
                    Label("共有", systemImage: "square.and.arrow.up")
                }
            }
    }
    
    private var qrImage: UIImage {
        let qrCodeGenerator = CIFilter.qrCodeGenerator()
        qrCodeGenerator.message = Data(data.utf8)
        qrCodeGenerator.correctionLevel = "H"
        if let outputimage = qrCodeGenerator.outputImage {
            if let cgImage = CIContext().createCGImage(
                outputimage, from: outputimage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return UIImage()
    }
}

#Preview {
    QrCodeView(data: "abc")
        .frame(width: 150, height: 150)
}
