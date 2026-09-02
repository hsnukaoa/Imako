//
//  ChatView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/06/28.
//

import SwiftUI
import FirebaseAuth
import DesignSystem
import FirebaseFirestore

struct SelectedImageURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct ChatView: View {
    @StateObject private var actionVM = ChatActionViewModel()
    @State private var showingBlockAlert = false
    @State private var showingBlockAndReportAlert = false
    @State var chat: Chats
    @State var text: String = ""
    @FocusState private var isFocused: Bool
    @StateObject private var viewModel = MessageViewModel()
    @StateObject private var vm = MessageListViewModel()
    @State private var showPicker: Bool = false
    @State private var imageData: Data?
    private var checkImage: Bool {
        return imageData != nil
    }
    @State private var imageURL : String = ""
    @State var imageText: String = ""
    @State private var selectedImage: SelectedImageURL?
    @StateObject private var statusVM = ChatStatusViewModel()
    @State private var showCompleteAlert: Bool = false
    @State private var chatDeleteVM = ChatsDeleteViewModel()

    private var isSender: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return chat.sentTo == uid
    }

    var body: some View {
        ScrollViewReader { proxy in
            if vm.messages.isEmpty{
                Spacer()
                Text("まだメッセージはありません")
                Spacer()
                footer
            }else if statusVM.isBlockedByOther{
                Spacer()
                HStack{
                    Image(systemName: "exclamationmark.triangle")
                    Text("チャットが存在しません")
                }
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
                if statusVM.isBlockedByOther{
                    Text("不明")
                        .font(.headline)
                }else{
                    Text(chat.item.name)
                        .font(.headline)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button{
                    guard let uid = Auth.auth().currentUser?.uid else { return }

                    Task {
                        await statusVM.toggleMute(
                            chatID: chat.id ?? "",
                            currentUserID: uid,
                            isCurrentlyMuted: statusVM.isMuted
                        )
                    }
                }label: {
                    if statusVM.isMuted {
                        Image(systemName: "speaker.slash")
                    } else {
                        Image(systemName: "speaker.wave.2")
                    }
                }
                .disabled(statusVM.isBlockedByOther)
            }

            ToolbarItem(placement: .secondaryAction) {
                if statusVM.isBlock {
                    Button {
                        actionVM.unblockUser(chat: chat) { success in
                            if success {
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("ブロックを解除")
                        }
                        .foregroundColor(.blue)
                    }
                    .disabled(statusVM.isBlockedByOther)
                } else {
                    Button {
                        showingBlockAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "nosign")
                            Text("ブロック")
                        }
                        .foregroundColor(.red)
                    }
                    .disabled(statusVM.isBlockedByOther || statusVM.isReportCompletedByMe)
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Button(role: .destructive) {
                    showingBlockAndReportAlert = true
                }label: {
                    HStack{
                        Image(systemName: "exclamationmark.bubble")
                        Text("ブロックして通報")
                    }
                }
                .disabled(statusVM.isBlock || statusVM.isBlockedByOther || statusVM.isReportCompletedByMe)
            }
        }
        .alert("ブロックしますか？", isPresented: $showingBlockAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("ブロックする", role: .destructive) {
                actionVM.blockUser(chat: chat) { success in
                    if success {
                    }
                }
            }
        } message: {
            Text("このユーザーからのメッセージを受け取れなくなります。")
        }
        .contentShape(Rectangle())
        .alert("ブロックして報告しますか？", isPresented: $showingBlockAndReportAlert){
            Button("キャンセル", role: .cancel){}
            Button("実行する", role: .destructive){
                if isSender{
                    actionVM.blockUser(chat: chat) { success in
                        if success {
                            Task {
                                await statusVM.blockAndReport(targetUserID: chat.sentTo, currentUserID: chat.sentBy, chatID: chat.id ?? "")
                            }
                        }
                    }
                }else{
                    actionVM.blockUser(chat: chat) { success in
                        if success {
                            Task {
                                await statusVM.blockAndReport(targetUserID: chat.sentBy, currentUserID: chat.sentTo, chatID: chat.id ?? "")
                            }
                        }
                    }
                }
            }
        } message: {
            Text("悪質なユーザーを運営に報告し、このユーザーからのメッセージを受け取らなくなります")
        }
        .alert("報告が完了しましたか？", isPresented: $showCompleteAlert){
            Button("キャンセル", role: .cancel){}
            Button("完了", role: .destructive){
                guard let uid = Auth.auth().currentUser?.uid, let chatID = chat.id else { return }
                Task {
                    await statusVM.completeReport(chatID: chatID, currentUserID: uid)
                }
            }
        } message:{
            Text("対応が完了したらこのボタンを押してください。完了後は相手からのメッセージ受信が停止しますが、あなたのメッセージは引き続き相手に表示されます。")
        }
        .onTapGesture {
            isFocused = false
        }
        .onAppear{
            vm.fetchMessages(chatID: chat.id!)
            if let chatID = chat.id {
                statusVM.listenToChatStatus(chatID: chatID)

                if let uid = Auth.auth().currentUser?.uid {
                    Firestore.firestore().collection("chats").document(chatID).updateData([
                        "unreadCounts.\(uid)": 0
                    ])
                }
            }
        }
        .fullScreenCover(item: $selectedImage) { selected in
            ImageDetailView(imageURL: selected.url)
        }
        .onDisappear {
            statusVM.stopListening()
            vm.stopListening()
        }
    }

    private var footer: some View{
        VStack(spacing: 0){
            HStack{
                if let imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(alignment: .topTrailing) {
                            Button{
                                self.imageData = nil
                            }label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white, .black.opacity(0.6))
                            }
                            .padding(8)
                            .buttonStyle(.plain)
                        }
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
                .disabled(statusVM.isBlock || statusVM.isBlockedByOther || statusVM.isReportCompletedByOther || statusVM.isReportCompletedByMe)

                if statusVM.isReportCompletedByMe{
                    HStack{
                        Spacer()
                        Text("報告は完了しました")
                            .padding(.horizontal)
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .frame(minHeight: 40)
                    .background(Color.mint.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                }else if statusVM.isReportCompletedByOther{
                    HStack{
                        Spacer()
                        Text("相手の報告は完了しました")
                            .padding(.horizontal)
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .frame(minHeight: 40)
                    .background(Color.mint.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                } else if imageData != nil {
                    HStack{
                        Spacer()
                        Text("写真を選択中")
                            .padding(.leading)
                            .padding(.trailing)
                            .frame(minHeight: 40)
                        Spacer()
                    }
                } else if !statusVM.isBlock{
                    TextField("Aa", text: $text, axis: .vertical)
                        .padding(.leading)
                        .padding(.trailing)
                        .frame(minHeight: 40)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .focused($isFocused)
                }else{
                    HStack{
                        Spacer()
                        Text("ブロック中")
                            .padding(.leading)
                            .padding(.trailing)
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .frame(minHeight: 40)
                    .background(Color.gray.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                }

                if !checkImage && text.hasnotContent{
                    Button{
                        showCompleteAlert = true
                        imageData = nil
                    }label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.mint)
                    }
                    .padding()
                    .buttonStyle(.plain)
                    .disabled(statusVM.isBlock || statusVM.isBlockedByOther || statusVM.isReportCompletedByMe)
                }else{
                    Button{
                        guard !statusVM.isBlock && !statusVM.isBlockedByOther else { return }

                        if checkImage{
                            ImageService.uploadToCloudinary(image: UIImage(data: imageData!)!) { result in
                                imageText = result!.url
                                viewModel.sendMessage(content: imageText, chatID: chat.id!, contentType: "image", imagePublicId: result?.publicId){ success in
                                    imageText = ""
                                }
                            }
                            imageData = nil
                        }else if !text.hasnotContent{
                            viewModel.sendMessage(content: text, chatID: chat.id!, contentType: "text", imagePublicId: nil){ success in
                                text = ""
                            }
                        }
                    }label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 25))
                            .foregroundStyle(.green)
                    }
                    .padding()
                    .buttonStyle(.plain)
                    .disabled(statusVM.isBlock || statusVM.isBlockedByOther || (text.hasnotContent && !checkImage))
                }

                Spacer()
            }
            .background(.white)
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
                        Text("メッセージの送信を取り消しました")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Capsule())
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
                        }
                    }else if isDelete{
                        Text("メッセージの送信を取り消しました")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Capsule())
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
            }
        }
    }
}

extension String {
    var hasnotContent: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
