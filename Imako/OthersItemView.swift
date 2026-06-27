//
//  OthersItemView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/26.
//

import SwiftUI
import FirebaseAuth

struct OthersItemView: View {
    @State var item: Item
    private let dbservice = DatabaseService()
    @State var ShowQRSheet: Bool = false
    @StateObject private var viewModel = ChatCreateViewModel()
    @State private var sentTo: String = ""
    
    var body: some View {
        var currentUserID: String{
            Auth.auth().currentUser!.uid
        }
        
        let sentToUserID: String = String(item.ownerID)
        
        ScrollView {
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
                    Text("連絡を取る")
                        .font(.title.bold())
                        .padding()
                    
                    Spacer()
                }
                .padding()
                
                Button{
                    viewModel.createChat(sentBy: currentUserID, sentTo: sentToUserID, itemName: item.name) {bool, docID in
                        if let docID = docID {
                            if let itemID = item.id {
                                viewModel.UpdateItemArray(chatID: docID, itemID: itemID) { success in
                                }
                                viewModel.UpdateUserArray(chatID: docID, finderID: currentUserID, dropperID: sentToUserID){ success in
                                }
                            }
                            
                        }
                    }
                }label: {
                    Text("チャットを開始する")
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(.capsule)
                }
                .glassEffect(.regular.interactive())
                .buttonStyle(.plain)
                .padding(.top)
                
            }
        }
        .ignoresSafeArea(edges: .top)
        .safeAreaBar(edge: .top){
            header
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
}

extension View {
    func stretchy() -> some View {
        visualEffect { effect, geometry in
            let currentHeight = geometry.size.height
            let scrollOffset = geometry.frame(in: .scrollView).minY
            let positiveOffset = max(0, scrollOffset)
            
            let newHeight = currentHeight + positiveOffset
            let scaleFactor = newHeight / currentHeight
            
            return effect.scaleEffect(
                x: scaleFactor, y: scaleFactor,
                anchor: .bottom
            )
        }
    }
}
