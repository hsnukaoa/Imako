//
//  ScanView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/01.
//

import SwiftUI

struct ScanView: View {
    @State private var path = NavigationPath()
    @State private var isScanning = false
    
    var body: some View {
        NavigationStack(path: $path) {
            QRCodeScanner(isScanning: $isScanning) { item in
                isScanning = false
                path.append(item)
            }
            .ignoresSafeArea()
            .onAppear {
                if path.isEmpty {
                    isScanning = true
                }
            }
            .onDisappear {
                isScanning = false
            }
            .navigationDestination(for: Item.self) { item in
                BranchDetailView(item: item)
            }
        }
        .onChange(of: path.count) { _, newCount in
            if newCount == 0 {
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    
                    if path.isEmpty {
                        isScanning = true
                    }
                }
            }
        }
    }
}
