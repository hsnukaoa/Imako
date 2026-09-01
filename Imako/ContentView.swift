//
//  ContentView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/01.
//

import SwiftUI

//TODO: アイテム読み取り時のブロックしている相手による画面遷移
//TODO: プライバシーポリシーの作成
//TODO: 問題解決ボタンの実装

struct ContentView: View {
    @ObservedObject var vm: AuthViewModel
    @StateObject var chatListVM: ChatListViewModel
    
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
                Image(systemName: "megaphone")
                Text("報告")
            }.tag(3)
                .badge(chatListVM.totalUnreadCount)
        }
        .onAppear(){
            chatListVM.startListeningChats()
        }
        .onDisappear(){
            chatListVM.stopListening()
        }
    }
}
