//
//  OwnersItemView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/26.
//

import SwiftUI
import FirebaseFirestore

struct OwnersItemView: View {
    @State var item: Item
    private let dbservice = DatabaseService()
    @State var ShowQRSheet: Bool = false
    @StateObject var viewModel = ChatListViewModel()
    @State private var chats: [Chats] = []
    @State private var isLoadingChats = false
    @State var showEditSheet: Bool = false
    
    @State private var itemListener: ListenerRegistration?
    
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
                
                Spacer()
                
                HStack{
                    Text("これはあなたの持ち物です")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding()
                }
                .background(Color.green.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 16))
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
        .onAppear {
            listenToItem()
        }
        .onDisappear {
            itemListener?.remove()
        }
        .toolbar{
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
        .sheet(isPresented: $showEditSheet){
            EditItemView(item: item)
        }
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
                showEditSheet = true
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
    
    private func listenToItem() {
        guard let itemID = item.id else { return }
        let db = Firestore.firestore()
        
        itemListener = db.collection("items").document(itemID).addSnapshotListener { snapshot, error in
            if error != nil {
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else { return }
            
            do {
                let updatedItem = try snapshot.data(as: Item.self)
                DispatchQueue.main.async {
                    self.item = updatedItem
                }
            } catch {
            }
        }
    }
}
