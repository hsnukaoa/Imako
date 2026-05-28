//
//  ChatsModel.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/05/17.
//

import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    var chatIDs: [String]?
}

struct Chats : Codable, Identifiable {
    @DocumentID var id: String?
    var sentBy: String
    var sentTo: String
    
    init(sentBy: String, sentTo: String){
        self.sentBy = sentBy
        self.sentTo = sentTo
    }
}

struct Message : Codable, Identifiable {
    @DocumentID var id: String?
    var content: String
    var createdAt: Date?
    var senderID: String
}
