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
                    emptyStateView
                } else {
                    VStack(spacing: 0) {
                        Picker("フィルター", selection: $selection) {
                            Text("全て").tag(ChatFilterType.all)
                            Text("拾った").tag(ChatFilterType.find)
                            Text("なくした").tag(ChatFilterType.lost)
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        
                        List {
                            ForEach(selectedChats) { chat in
                                ChatList(chat: chat) {
                                    if let chatId = chat.id {
                                        viewModel.removeChatLocally(chatID: chatId)
                                        
                                        Task {
                                            do {
                                                try await chatDeletevm.deleteChat(chatId: chatId)
                                            } catch {
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                headerView
                    .background(Color(uiColor: .systemBackground))
            }
        }
        .onAppear {
            viewModel.startListeningChats()
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("報告")
                .font(.largeTitle.bold())
                .padding()
            
            Spacer()
            
            NavigationLink(destination: UserView()) {
                Image(systemName: "person.fill")
                    .frame(width: 47, height: 47)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Image(systemName: "tray")
                .font(.custom("a", size: 60))
                .foregroundStyle(.tint)
                .padding()
            Text("報告中の持ち物なし")
                .font(.title)
                .padding(.top, 8)
            Spacer()
        }
    }
}

struct ChatList: View {
    let chat: Chats
    let onDelete: () -> Void
    
    @State private var showDetail = false
    @State private var showChat = false
    @StateObject private var statusVM = ChatStatusViewModel()
    
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
        HStack(spacing: 12) {
            Button {
                showDetail = true
            } label: {
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
            .buttonStyle(.borderless)
            
            Button {
                showChat = true
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        HStack{
                            Text(chat.item.name)
                                .font(.headline)
                                .foregroundStyle(.black)
                                .padding(.top)
                            if statusVM.isMuted{
                                Image(systemName: "speaker.slash")
                                    .font(.headline)
                                    .foregroundStyle(.gray)
                                    .padding(.top)
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                    
                    if isOwner {
                        if let count = chat.unreadCounts?[chat.sentTo], count > 0 {
                            Text("\(count)")
                                .font(.caption.bold())
                                .padding(12)
                                .foregroundColor(.white)
                                .background(Color.green)
                                .clipShape(Circle())
                        }
                    } else {
                        if let count = chat.unreadCounts?[chat.sentBy], count > 0 {
                            Text("\(count)")
                                .font(.caption.bold())
                                .padding(12)
                                .foregroundColor(.white)
                                .background(Color.green)
                                .clipShape(Circle())
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                onDelete()
            } label: {
                Text("削除")
            }
            .tint(.red)
            
            Button {
                guard let uid = Auth.auth().currentUser?.uid else { return }
                
                Task {
                    await statusVM.toggleMute(
                        chatID: chat.id ?? "",
                        currentUserID: uid,
                        isCurrentlyMuted: statusVM.isMuted
                    )
                }
            } label: {
                if statusVM.isMuted {
                    Image(systemName: "speaker.wave.2")
                } else {
                    Image(systemName: "speaker.slash")
                }
            }
            .tint(.cyan)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false){
            Button{
                
            }label: {
                Image(systemName: "checkmark.circle")
            }
            .tint(.green)
        }
        .navigationDestination(isPresented: $showDetail) {
            BranchDetailView(item: fixedItem)
        }
        .navigationDestination(isPresented: $showChat) {
            ChatView(chat: chat)
        }
        .onAppear {
            statusVM.listenToChatStatus(chatID: chat.id ?? "")
        }
        .onDisappear {
            statusVM.stopListening()
        }
    }
}
