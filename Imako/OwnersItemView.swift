//
//  OwnersItemView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/26.
//

import SwiftUI

struct OwnersItemView: View {
    @State var item: Item
    private let dbservice = DatabaseService()
    @State var ShowQRSheet: Bool = false
    @StateObject var viewModel = ChatListViewModel()
    @State private var chats: [Chats] = []
    @State private var isLoadingChats = false
    
    var body: some View {
        ScrollView{
            VStack {
                if let url = URL(string: item.imageURL) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 450)
                                .clipped()
                                .stretchy()
                        } else if phase.error != nil {
                            Image(systemName: "photo.badge.exclamationmark")
                                .foregroundStyle(.gray)
                        } else {
                            ProgressView()
                        }
                    }
                }
                
                HStack{
                    Text("なくした回数:\(String(item.lostNumber ?? 0))")
                        .font(.title.bold())
                        .padding()
                    Spacer()
                }
                .padding()
                
                HStack{
                    Text("関連チャット")
                        .font(.title.bold())
                        .padding()
                    
                    Spacer()
                }
                .padding()
                
                LazyVStack{
                    ForEach(chats) { chat in
                        NavigationLink(destination: ChatView(chat: chat)){
                            HStack {
                                Color.blue
                                    .frame(width: 70, height: 70)
                                    .clipShape(.circle)
                                    .padding(.trailing, 0)
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
                .padding()
                
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
        }
        .ignoresSafeArea(edges: .top)
        .safeAreaBar(edge: .top) {
            header
        }
        .safeAreaBar(edge: .bottom) {
            footer
                .padding()
        }
        .task {
            await loadChats()
        }
        .toolbar{
            ToolbarItem(placement:.topBarTrailing){
                Button{
                    item.canCall.toggle()
                    
                    if let itemID = item.id {
                        dbservice.updateCanCall(itemID: itemID, canCall: item.canCall)
                    }
                }label:{
                    Image(systemName: "phone.badge.checkmark")
                        .foregroundStyle(.black)
                }
                .buttonStyle(.borderedProminent)
                .tint(item.canCall ? Color.teal.opacity(0.6) : Color.gray.opacity(0.3))
                .id(item.canCall)
            }
            
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            
            ToolbarItem(placement:.topBarTrailing){
                Button{
                    ShowQRSheet.toggle()
                }label: {
                    Image(systemName: "qrcode")
                        .foregroundStyle(Color.black)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.yellow.opacity(0.3))
            }
        }
        .fullScreenCover(isPresented: $ShowQRSheet){
            ShowQRView(item: item)
        }
        .toolbar(.hidden, for: .tabBar)
    }
    
    private var header: some View {
        HStack {
            Text(item.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.leading)
            Spacer()
        }
    }
    
    private var footer: some View {
        HStack{
            Spacer()
            Button{
            }label: {
                Image(systemName: "square.and.pencil")
                    .font(.title2)
            }
            .padding()
            .glassEffect(.regular.interactive(), in: .circle)
            .buttonStyle(.plain)
        }
    }
    
    @MainActor
    private func loadChats() async {
        guard !isLoadingChats else { return }
        isLoadingChats = true
        defer { isLoadingChats = false }
        if let fetched: [Chats] = await viewModel.fetchChatsFromItem(item) {
            chats = fetched
        } else {
            chats = []
        }
    }
}
