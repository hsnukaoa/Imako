//
//  ItemModels.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/19.
//


import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    var uid: String?
    var chatIDs: [String]?
    
    init(uid: String){
        self.uid = uid
        self.chatIDs = []
    }
}

struct Chats : Codable, Identifiable {
    @DocumentID var id: String?
    var sentBy: String
    var sentTo: String
    var itemID: String
    var item: Item
    
    init(sentBy: String, sentTo: String, item: Item){
        self.sentBy = sentBy
        self.sentTo = sentTo
        self.item = item
        self.itemID = item.id!
    }
}

struct Message : Codable, Identifiable {
    @DocumentID var id: String?
    var content: String
    var createdAt: Date?
    var senderID: String
    
    init(content: String, senderID: String){
        self.content = content
        self.senderID = senderID
        self.createdAt = Date()
    }
}

struct Item: Codable, Identifiable, Hashable{
    @DocumentID var id : String?
    var name : String
    var ownerID : String
    var imageURL : String
    var canCall : Bool
    var createdAt: Date?
    var lostNumber: Int?
    var chatIDs: [String]?
    var imagePublicId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case ownerID
        case imageURL
        case canCall
        case createdAt
        case lostNumber
        case imagePublicId
        
        case chatIDs = "chats"
    }
    
    init(name: String, ownerID : String, imageURL: String, canCall: Bool, lostNumber: Int?) {
        self.name = name
        self.ownerID = ownerID
        self.imageURL = imageURL
        self.canCall = canCall
        self.createdAt = Date()
        if let url = URL(string: imageURL) {
            let publicId = url.deletingPathExtension().lastPathComponent
            self.imagePublicId = publicId
        } else {
            self.imagePublicId = nil
        }
        self.lostNumber = lostNumber
    }
}
