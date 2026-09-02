//
//  MessageListViewModel.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/06/28.
//

import Foundation
import FirebaseFirestore
import SwiftUI
import Combine

class MessageListViewModel: ObservableObject{
    @Published var messages: [Message] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func fetchMessages(chatID: String){
        stopListening()
        
        db.collection("chats").document(chatID).collection("messages")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                
                self.messages = documents.compactMap{ doc in
                    try? doc.data(as: Message.self)
                }
            }
    }
    
    func stopListening(){
        listener?.remove()
        listener = nil
    }
}
