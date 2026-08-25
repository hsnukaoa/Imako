//
//  ContactView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/01.
//

import SwiftUI
import FirebaseAuth

enum ChatFilterType: String, CaseIterable, Identifiable {
    case all = "全て"
    case find = "拾った"
    case lost = "なくした"
    
    var id: String { self.rawValue }
}

struct ContactView: View {
    @StateObject private var viewModel = ChatListViewModel()
    @ObservedObject var vm: AuthViewModel
    @State private var selection: ChatFilterType = .all
    @StateObject private var chatDeletevm = ChatsDeleteViewModel()
    
    private var selectedChats: [Chats] {
        switch selection {
        case .all:
            return viewModel.chats
        case .find:
            return viewModel.findItemChats
        case .lost:
            return viewModel.lostItemChats
        }
    }
    
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
                    VStack(spacing: 0) {
                        Picker("フィルター", selection: $selection) {
                            Text("全て").tag(ChatFilterType.all)
                            Text("拾った").tag(ChatFilterType.find)
                            Text("なくした").tag(ChatFilterType.lost)
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        
                        ScrollView {
                            List {
                                ForEach(selectedChats) { chat in
                                    ChatList(chat: chat)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false){
                                            Button {
                                                Task {
                                                    try await chatDeletevm.deleteChat(chatId: chat.id!)
                                                }
                                            } label: {
                                                Text("削除")
                                            }
                                            .tint(.red)
                                        }
                                }
                            }
                            .listStyle(.plain)
                            .padding()
                        }
                        .scrollEdgeEffectStyle(.soft, for: .top)
                    }
                    .safeAreaInset(edge: .top) {
                        headerView
                            .background(Color(uiColor: .systemBackground))
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
            
            NavigationLink(destination: UserView()){
                Image(systemName: "person.fill")
                    .frame(width:47, height: 47)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
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
    
    private var fixedItem: Item {
        var item = chat.item
        item.id = chat.itemID
        return item
    }
    
    var body: some View {
        HStack {
            NavigationLink(destination: BranchDetailView(item: fixedItem)) {
                ZStack {
                    Color(isOwner ? .red : .blue)
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                    
                    if let url = URL(string: chat.item.imageURL) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                            } else if phase.error != nil {
                                Image(systemName: "photo.badge.exclamationmark")
                                    .foregroundStyle(.gray)
                            } else {
                                ProgressView()
                            }
                        }
                        .frame(width: 65, height: 65)
                        .clipShape(Circle())
                    }
                }
            }
            .buttonStyle(.plain)
            
            NavigationLink(destination: ChatView(chat: chat)) {
                HStack {
                    VStack {
                        Text(chat.item.name)
                            .font(.headline)
                            .lineLimit(1)
                            .padding(.top)
                        Spacer()
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
