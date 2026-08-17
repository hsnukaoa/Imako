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

class ChatListViewModel: ObservableObject {
    @Published var chats: [Chats] = []
    @Published var findItemChats: [Chats] = []
    @Published var lostItemChats: [Chats] = []
    private let db = Firestore.firestore()
    
    func fetchChats() async {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let docRef = db.collection("users").document(currentUserID)
        
        do {
            let document = try await docRef.getDocument()
            let chatIDs = document.data()?["chats"] as? [String] ?? []
            
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
            
            let fetchedFindItemChats = fetchedChats.filter { $0.sentBy == currentUserID }
            let fetchedLostItemChats = fetchedChats.filter { $0.sentBy != currentUserID }
            
            DispatchQueue.main.async {
                self.chats = fetchedChats
                self.findItemChats = fetchedFindItemChats
                self.lostItemChats = fetchedLostItemChats
            }
            
        } catch {
            print("ユーザーデータ、またはチャットの取得に失敗しました: \(error.localizedDescription)")
        }
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
}
