//
//  ContentView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/01.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var vm: AuthViewModel
    
    var body: some View {
        TabView {
            ItemView().tabItem {
                Image(systemName: "bag")
                Text("持ち物")
            }.tag(1)
            ScanView().tabItem {
                Image(systemName: "qrcode.viewfinder")
                Text("読み取り")
            }.tag(2)
            ContactView(vm: vm).tabItem{
                Image(systemName: "bubble.right")
                Text("連絡")
            }.tag(3)
        }
    }
}

#Preview {
    let previewVM = AuthViewModel()
    ContentView(vm: previewVM)
}
