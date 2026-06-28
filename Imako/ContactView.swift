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
    @ObservedObject var vm: AuthViewModel
    
    var body: some View {
        NavigationStack {
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
            
            Button{
                vm.signOut()
            }label: {
                Circle()
                    .frame(width: 45, height: 45).foregroundColor(.red)
            }
            .buttonStyle(.plain)
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
        NavigationLink(destination: ChatView(chat: chat)){
            HStack {
                if isOwner {
                    Color.red
                        .frame(width: 70, height: 70)
                        .clipShape(.circle)
                        .padding(.trailing, 0)
                }else{
                    Color.blue
                        .frame(width: 70, height: 70)
                        .clipShape(.circle)
                        .padding(.trailing, 0)
                }
                VStack{
                    Text(chat.itemName)
                        .font(.headline)
                        .lineLimit(1)
                        .padding()
                    Spacer()
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

