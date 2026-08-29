//
//  ChatView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/06/28.
//

import SwiftUI
import FirebaseAuth
import DesignSystem

struct SelectedImageURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct ChatView: View {
    @State var chat: Chats
    @State var text: String = ""
    @FocusState private var isFocused: Bool
    @ObservedObject private var viewModel = MessageViewModel()
    @ObservedObject private var vm = MessageListViewModel()
    @State private var showPicker: Bool = false
    @State private var imageData: Data?
    private var checkImage: Bool {
        return imageData != nil
    }
    @State private var imageURL : String = ""
    @State var imageText: String = ""
    @State private var selectedImage: SelectedImageURL?
    
    var body: some View {
        ScrollViewReader { proxy in
            if vm.messages.isEmpty{
                Spacer()
                Text("まだメッセージはありません")
                Spacer()
            }else {
                ScrollView {
                    LazyVStack{
                        ForEach(vm.messages) { message in
                            MessageList(message: message, chat: chat) { tappedURL in
                                self.selectedImage = SelectedImageURL(url: tappedURL)
                            }
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    footer
                }
                .onChange(of: vm.messages.count) { oldValue, newValue in
                    if let lastMessage = vm.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    if let lastMessage = vm.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar{
            ToolbarItem(placement: .title) {
                Text(chat.item.name)
                    .font(.headline)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = false
        }
        .onAppear{
            vm.fetchMessages(chatID: chat.id!)
        }
        .fullScreenCover(item: $selectedImage) { selected in
            ImageDetailView(imageURL: selected.url)
        }
    }
    
    private var footer: some View{
        VStack{
            HStack{
                if let imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding()
                }
                Spacer()
            }
            .background(.ultraThinMaterial)
            
            HStack{
                Spacer()
                Button{
                    showPicker = true
                }label: {
                    Image(systemName: "plus")
                        .font(.system(size: 25))
                }
                .padding()
                .buttonStyle(.plain)
                .imagePicker(isPresented: $showPicker, selectedImageData: $imageData)
                
                TextField("Aa", text: $text, axis: .vertical)
                    .padding(.leading)
                    .padding(.trailing)
                    .frame(minHeight: 40)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .focused($isFocused)
                
                Button{
                    if !text.hasnotContent{
                        viewModel.sendMessage(content: text, chatID: chat.id!, contentType: "text", imagePublicId: nil){ success in
                            text = ""
                        }
                    }else if checkImage{
                        ImageService.uploadToCloudinary(image: UIImage(data: imageData!)!) { result in
                            imageText = result!.url
                            viewModel.sendMessage(content: imageText, chatID: chat.id!, contentType: "image", imagePublicId: result?.publicId){ success in
                                imageText = ""
                            }
                        }
                        imageData = nil
                    }
                }label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 25))
                        .foregroundStyle(.green)
                }
                .padding()
                .buttonStyle(.plain)
                .disabled(text.hasnotContent && !checkImage)
                
                Spacer()
            }
        }
    }
}

struct MessageList: View {
    @ObservedObject private var viewModel = MessageViewModel()
    let message: Message
    let chat: Chats
    var onImageTapped: ((URL) -> Void)? = nil
    
    private var isSender: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return message.senderID == uid
    }
    
    private var isText: Bool {
        message.contentType == "text"
    }
    
    private var isImage: Bool {
        message.contentType == "image"
    }
    
    private var isDelete: Bool {
        message.contentType == "Delete"
    }
    
    var body: some View {
        HStack {
            if isSender {
                HStack{
                    Spacer()
                    VStack{
                        Spacer()
                        Text(message.createdAt!, style: .time)
                            .font(.callout)
                            .foregroundStyle(.gray)
                    }
                    if isText{
                        Text(message.content!)
                            .padding()
                            .foregroundStyle(.white)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .contextMenu{
                                Button{
                                    Task {
                                        await viewModel.unsendMessage(message: message, chat: chat)
                                    }
                                }label: {
                                    Text("送信取り消し")
                                }
                            }
                    }else if isImage{
                        if let url = URL(string: message.content!) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable()
                                        .scaledToFit()
                                } else if phase.error != nil {
                                    Image(systemName: "photo.badge.exclamationmark")
                                        .foregroundStyle(.gray)
                                } else {
                                    ProgressView()
                                }
                            }
                            .frame(height: 200)
                            .onTapGesture {
                                onImageTapped?(url)
                            }
                            .contextMenu{
                                Button{
                                    Task {
                                        await viewModel.unsendMessage(message: message, chat: chat)
                                    }
                                }label: {
                                    Text("送信取り消し")
                                }
                            }
                        }
                    }else if isDelete{
                        Text("送信取り消し")
                            .font(.callout)
                            .foregroundStyle(.white)
                            .background(.gray)
                            .padding()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }else{
                        Text("不明なエラー")
                            .font(.callout)
                            .foregroundStyle(.white)
                            .background(.red)
                            .padding()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }else{
                HStack{
                    if isText{
                        Text(message.content!)
                            .padding()
                            .foregroundStyle(.white)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .contextMenu{
                                Button{
                                    Task {
                                        await viewModel.unsendMessage(message: message, chat: chat)
                                    }
                                }label: {
                                    Text("送信取り消し")
                                }
                            }
                    }else if isImage{
                        if let url = URL(string: message.content!) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable()
                                        .scaledToFit()
                                } else if phase.error != nil {
                                    Image(systemName: "photo.badge.exclamationmark")
                                        .foregroundStyle(.gray)
                                } else {
                                    ProgressView()
                                }
                            }
                            .frame(height: 200)
                            .onTapGesture {
                                onImageTapped?(url)
                            }
                            .contextMenu{
                                Button{
                                    Task {
                                        await viewModel.unsendMessage(message: message, chat: chat)
                                    }
                                }label: {
                                    Text("送信取り消し")
                                }
                            }
                        }
                    }else if isDelete{
                        Text("送信取り消し")
                            .font(.callout)
                            .foregroundStyle(.white)
                            .background(.gray)
                            .padding()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }else{
                        Text("不明なエラー")
                            .font(.callout)
                            .foregroundStyle(.white)
                            .background(.red)
                            .padding()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    VStack{
                        Spacer()
                        Text(message.createdAt!, style: .time)
                            .font(.callout)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
            }
        }
    }
}

struct ImageDetailView: View {
    let imageURL: URL
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            AsyncImage(url: imageURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                } else if phase.error != nil {
                    Image(systemName: "photo.badge.exclamationmark")
                        .foregroundColor(.white)
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            saveImageToPhotoLibrary()
                        } label: {
                            Label("端末に保存", systemImage: "arrow.down.to.line")
                        }
                        
                        Button {
                            
                        } label: {
                            Label("転送", systemImage: "arrowshape.turn.up.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                Spacer()
            }
        }
    }
    
    private func saveImageToPhotoLibrary() {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                if let uiImage = UIImage(data: data) {
                    UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                }
            } catch {
                print("画像のダウンロードに失敗しました: \(error)")
            }
        }
    }
}

extension String {
    var hasnotContent: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

