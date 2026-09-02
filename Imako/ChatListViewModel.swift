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
            
            if error != nil {
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
                    
                    if error != nil {
                        return
                    }
                    
                    guard let doc = documentSnapshot, doc.exists else { return }
                    
                    do {
                        let chat = try doc.data(as: Chats.self)
                        self.currentChatsMap[chatID] = chat
                        self.updatePublishedProperties(currentUserID: currentUserID)
                    } catch {
                    }
                }
                chatListeners[chatID] = listener
            }
        }
        
        updatePublishedProperties(currentUserID: currentUserID)
    }
    
    private func updatePublishedProperties(currentUserID: String) {
        let allChats = Array(self.currentChatsMap.values)
        
        let visibleChats = allChats
            .filter { $0.visibleTo.contains(currentUserID) }
            .sorted { ($0.updatedAt ?? $0.createdAt ?? Date.distantPast) > ($1.updatedAt ?? $1.createdAt ?? Date.distantPast) }        
        self.chats = visibleChats
        self.findItemChats = visibleChats.filter { $0.sentBy == currentUserID }
        self.lostItemChats = visibleChats.filter { $0.sentBy != currentUserID }
        
        let totalUnread = visibleChats.reduce(0) { sum, chat in
            let myUnreadCount = chat.unreadCounts?[currentUserID] ?? 0
            return sum + myUnreadCount
        }
        self.totalUnreadCount = totalUnread
        
        UNUserNotificationCenter.current().setBadgeCount(totalUnread) { error in
            if error != nil {
            }
        }
    }
    
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
    
    func removeChatLocally(chatID: String) {
        self.chats.removeAll { $0.id == chatID }
        self.findItemChats.removeAll { $0.id == chatID }
        self.lostItemChats.removeAll { $0.id == chatID }
        
        self.currentChatsMap.removeValue(forKey: chatID)
        
        chatListeners[chatID]?.remove()
        chatListeners.removeValue(forKey: chatID)
    }
    
    func markAsRead(chatID: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        db.collection("chats").document(chatID).updateData([
            "unreadCounts.\(currentUserID)": 0
        ])
    }
}
