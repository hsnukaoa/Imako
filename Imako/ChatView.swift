//
//  ChatView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/06/28.
//

import SwiftUI
import FirebaseAuth

struct ChatView: View {
    @State var chat: Chats
    @State var text: String = ""
    @FocusState private var isFocused: Bool
    @ObservedObject private var viewModel = SendMessageViewModel()
    @ObservedObject private var vm = MessageListViewModel()
    
    
    var body: some View {
        VStack{
            if vm.messages.isEmpty{
                Spacer()
                Text("まだメッセージはありません")
                Spacer()
            }else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack{
                            ForEach(vm.messages) { message in
                                MessageList(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: vm.messages.count) { oldValue, newValue in
                        if let lastMessage = vm.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    // 画面が表示されたときに一番下へスクロール
                    .onAppear {
                        if let lastMessage = vm.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            footer
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar{
            ToolbarItem(placement: .title) {
                Text(chat.itemName)
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
    }
    
    private var footer: some View{
        HStack{
            Spacer()
            
            Button{
                
            }label: {
                Image(systemName: "plus")
                    .font(.system(size: 25))
            }
            .padding()
            .buttonStyle(.plain)
            
            TextField("Aa", text: $text, axis: .vertical)
                .padding(.leading)
                .padding(.trailing)
                .frame(minHeight: 40)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .focused($isFocused)
            
            Button{
                viewModel.sendMessage(content: text, chatID: chat.id!){ success in
                    text = ""
                }
            }label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 25))
                    .foregroundStyle(.green)
            }
            .padding()
            .buttonStyle(.plain)
            .disabled(text.hasnotContent)
            
            Spacer()
        }
    }
}

struct MessageList: View {
    let message: Message
    
    private var isSender: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return message.senderID == uid
    }
    
    var body: some View {
        HStack {
            if isSender {
                HStack{
                    Spacer()
                    Text(message.content)
                        .padding()
                        .foregroundStyle(.white)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }else{
                HStack{
                    Text(message.content)
                        .padding()
                        .foregroundStyle(.white)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    Spacer()
                }
            }
        }
        
    }
}

extension String {
    /// 改行、タブ、スペースしか含まれていない場合は true を返す
    var hasnotContent: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

