//
//  ScanView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/01.
//

import SwiftUI

struct ScanView: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            QRCodeScanner { item in
                path.append(item)
            }
            .ignoresSafeArea()
            .navigationDestination(for: Item.self) { item in
                BranchDetailView(item: item)
            }
        }
    }
}
