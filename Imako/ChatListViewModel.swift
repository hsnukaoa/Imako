//
//  ChatListViewModel.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/06/19.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

@MainActor
class ChatListViewModel: ObservableObject {
    @Published var chats: [Chats] = []
    @Published var findItemChats: [Chats] = []
    @Published var lostItemChats: [Chats] = []
    @Published var totalUnreadCount: Int = 0
    
    private let db = Firestore.firestore()
    
    private var userListener: ListenerRegistration?
    private var chatListeners: [String: ListenerRegistration] = [:]
    
    private var currentChatsMap: [String: Chats] = [:]
    
    func startListeningChats() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let docRef = db.collection("users").document(currentUserID)
        
        userListener = docRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("ユーザーデータの監視に失敗しました: \(error.localizedDescription)")
                return
            }
            
            guard let document = documentSnapshot else { return }
            let chatIDs = document.data()?["chats"] as? [String] ?? []
            
            self.updateChatListeners(chatIDs: chatIDs, currentUserID: currentUserID)
        }
    }
    
    private func updateChatListeners(chatIDs: [String], currentUserID: String) {
        for (id, listener) in chatListeners {
            if !chatIDs.contains(id) {
                listener.remove()
                chatListeners.removeValue(forKey: id)
                currentChatsMap.removeValue(forKey: id)
            }
        }
        
        for chatID in chatIDs {
            if chatListeners[chatID] == nil {
                let listener = db.collection("chats").document(chatID).addSnapshotListener { [weak self] documentSnapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("チャット(\(chatID))の監視エラー: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let doc = documentSnapshot, doc.exists else { return }
                    
                    do {
                        let chat = try doc.data(as: Chats.self)
                        self.currentChatsMap[chatID] = chat
                        self.updatePublishedProperties(currentUserID: currentUserID)
                    } catch {
                        print("チャットのデコードに失敗しました: \(error.localizedDescription)")
                    }
                }
                chatListeners[chatID] = listener
            }
        }
        
        updatePublishedProperties(currentUserID: currentUserID)
    }
    
    // MARK: - UIプロパティの更新
    private func updatePublishedProperties(currentUserID: String) {
        let allChats = Array(self.currentChatsMap.values)
        // 例: 日付順にソートする場合（ChatsモデルにcreatedAt等がある場合）
        // let sortedChats = allChats.sorted { $0.createdAt > $1.createdAt }
        
        self.chats = allChats
        self.findItemChats = allChats.filter { $0.sentBy == currentUserID }
        self.lostItemChats = allChats.filter { $0.sentBy != currentUserID }
    }
    
    // MARK: - 監視の停止（画面遷移時やログアウト時などに呼ぶ）
    func stopListening() {
        userListener?.remove()
        userListener = nil
        
        for (_, listener) in chatListeners {
            listener.remove()
        }
        chatListeners.removeAll()
        currentChatsMap.removeAll()
    }
    
    func fetchChatsFromID(_ chatID: String) async -> Chats? {
        do {
            let chatDoc = try await db.collection("chats").document(chatID).getDocument()
            return try? chatDoc.data(as: Chats.self)
        } catch {
            print("チャットの取得に失敗しました: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchChatsFromItem(_ item: Item) async -> [Chats]? {
        guard let chatIDs = item.chatIDs else { return [] }
        
        let fetchedChats = await withTaskGroup(of: DocumentSnapshot?.self) { group in
            for chatID in chatIDs {
                group.addTask {
                    return try? await self.db.collection("chats").document(chatID).getDocument()
                }
            }
            
            var results: [Chats] = []
            for await doc in group {
                if let doc = doc, let chat = try? doc.data(as: Chats.self) {
                    results.append(chat)
                }
            }
            return results
        }
        return fetchedChats
    }
    
    // MARK: - ローカル削除（Optimistic UI用）
    func removeChatLocally(chatID: String) {
        // 1. UIにバインドされている配列から即座に削除
        self.chats.removeAll { $0.id == chatID }
        self.findItemChats.removeAll { $0.id == chatID }
        self.lostItemChats.removeAll { $0.id == chatID }
        
        // 2. マップから削除
        self.currentChatsMap.removeValue(forKey: chatID)
        
        // 3. リスナーを解除
        chatListeners[chatID]?.remove()
        chatListeners.removeValue(forKey: chatID)
    }
}
