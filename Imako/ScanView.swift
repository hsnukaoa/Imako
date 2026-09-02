//
//  ScanView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/01.
//

import SwiftUI
import AVFoundation
import Combine

class CameraPermissionManager: ObservableObject {
    @Published var isDenied = false
    
    func checkPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        DispatchQueue.main.async {
            switch status {
            case .denied, .restricted:
                self.isDenied = true
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        self.isDenied = !granted
                    }
                }
            case .authorized:
                self.isDenied = false
            @unknown default:
                break
            }
        }
    }
    
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

struct ScanView: View {
    @State private var path = NavigationPath()
    @State private var isScanning = false
    @StateObject private var permissionManager = CameraPermissionManager()
    @State private var showPermissinonAlert: Bool = false
    
    var body: some View {
        VStack{
            if permissionManager.isDenied{
                HStack {
                    Spacer()
                    VStack{
                        Spacer()
                        
                        Image(systemName: "camera.badge.ellipsis")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        
                        Text("カメラへのアクセス許可が必要です")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Text("アプリから写真を撮影するには、設定からカメラのアクセスを許可してください。")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            permissionManager.openSettings()
                        }) {
                            Text("設定アプリを開く")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    
                    Spacer()
                }
                .frame(width: .infinity,height: .infinity)
                .ignoresSafeArea()
                .onAppear {
                    showPermissinonAlert = true
                }
                .background(.black)
            }else{
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
        .onAppear(){
            permissionManager.checkPermission()
        }
    }
}

