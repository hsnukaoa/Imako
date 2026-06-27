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
    private let db = Firestore.firestore()
    
    func fetchChats() async {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let docRef = db.collection("users").document(currentUserID)
        
        do {
            let document = try await docRef.getDocument()
            let chatIDs = document.data()?["chats"] as? [String] ?? []
            
            var fetchedChats: [Chats] = []
            
            for chatID in chatIDs {
                let chatDoc = try await db.collection("chats").document(chatID).getDocument()
                
                if let chat = try? chatDoc.data(as: Chats.self) {
                    fetchedChats.append(chat)
                }
            }
            
            DispatchQueue.main.async {
                self.chats = fetchedChats
            }
            
        } catch {
            print("ユーザーデータ、またはチャットの取得に失敗しました: \(error.localizedDescription)")
        }
    }
}
