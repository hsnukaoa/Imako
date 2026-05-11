//
//  ScanView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/01.
//

import SwiftUI

struct ScanView: View {
    @State  private var itemID: String
    
    var body: some View {
        QRCodeScanner(recognizedPayload: $itemID)
            .ignoresSafeArea()
    }
}
