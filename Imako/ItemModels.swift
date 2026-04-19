//
//  ItemModels.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/19.
//

import Foundation
import FirebaseFirestore

struct Item: Codable, Identifiable{
    @DocumentID var id : String?
    var name : String
    var ownerID : String
    var imageURL : String
    var cancall : Bool
    var createdAt: Date?
    
    init(name: String, ownerID: String, imageURL: String, canCall: Bool){
        self.name = name
        self.ownerID = ownerID
        self.imageURL = imageURL
        self.cancall = canCall
        self.createdAt = Date()
    }
}
