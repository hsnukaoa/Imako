//
//  ContactView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/01.
//

import SwiftUI
import FirebaseAuth

struct ContactView: View {
    @ObservedObject private var viewModel = ChatListViewModel()
    
    var body: some View {
        Group {
            if viewModel.chats.isEmpty {
                VStack {
                    headerView
                    
                    Spacer()
                    Image(systemName: "binoculars")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.tint)
                    Text("会話がありません")
                        .font(.title)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.chats) { chat in
                            ChatList(chat: chat)
                        }
                    }
                    .padding()
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
                .safeAreaBar(edge: .top) {
                    headerView
                }
            }
        }
        .task {
            await viewModel.fetchChats()
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("連絡")
                .font(.largeTitle.bold())
                .padding()
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct ChatList: View {
    let chat: Chats
    
    private var isOwner: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return chat.sentTo == uid
    }
    
    var body: some View {
        HStack {
            if isOwner {
                Color.red
                    .frame(width: 100, height: 165)
            }else{
                Color.blue
                    .frame(width: 100, height: 165)
            }
            
            Text(chat.itemName)
                .font(.headline)
                .lineLimit(1)
                .padding()
            
            Spacer()
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.background)
                .shadow(color: Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1)), radius: 4, x: 2, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.black, lineWidth: 1)
        )
    }
}

