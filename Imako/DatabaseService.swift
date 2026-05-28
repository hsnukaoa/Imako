//
//  DatabaseService.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/19.
//

import Foundation
import FirebaseFirestore
import Combine
import FirebaseAuth
import UIKit

class DatabaseService {
    private let db = Firestore.firestore()
    
    func saveItem(item: Item, completion: @escaping (String?) -> Void){
        do{
            let ref = try db.collection("items").addDocument(from: item)
            completion(ref.documentID)
        }catch {
            print("FirebaseFirestore保存エラー: \(error)")
            completion(nil)
        }
    }
    
    func updateCanCall(itemID: String, canCall: Bool) {
        db.collection("items").document(itemID).updateData([
            "canCall": canCall
        ]) { error in
            if let error = error {
                print("Firebase更新エラー: \(error)")
            }
        }
    }
    
    func createChat(chat: Chats, completion: @escaping (String?) -> Void){
        do{
            let ref = try db.collection("chats").addDocument(from: chat)
            completion(ref.documentID)
        }catch{
            print("FirebaseFirestore保存エラー: \(error)")
            completion(nil)
        }
    }
    
    func registerUser(user: User, completion: @escaping (String?) -> Void) {
        do{
            let ref = try db.collection("users").addDocument(from: user)
            completion(ref.documentID)
        }catch{
            print("FirebaseFireStore保存エラー: \(error)")
            completion(nil)
        }
    }
}

class ItemRegistrationViewModel: ObservableObject{
    @Published var isSaving = false
    private let dbService = DatabaseService()
    
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    func registerNewItem(name: String, image: UIImage, canCall: Bool, lostNumber: Int?, completion: @escaping () -> Void) {
        
        guard let uid = currentUserID else {
            print("エラー: ログインしていません")
            return
        }
        
        isSaving = true
        
        ImageService.uploadToCloudinary(image: image) { imageUrl in
            guard let url = imageUrl else {
                print("画像アップロード失敗")
                DispatchQueue.main.async {
                    self.isSaving = false
                }
                return
            }
            
            let newItem = Item(
                name: name,
                ownerID: uid,
                imageURL: url,
                canCall: canCall,
                lostNumber: lostNumber ?? 0
            )
            
            self.dbService.saveItem(item: newItem) { documentID in
                DispatchQueue.main.async {
                    self.isSaving = false
                    
                    completion()
                }
            }
        }
    }
}

class ChatCreateViewModel: ObservableObject{
    private let dbService = DatabaseService()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    func createChat(sentBy: String, sentTo: String, completion: @escaping () -> Void) {
        guard let uid = currentUserID else {
            print("エラー: ログインしていません")
            return
        }
        
        let chat = Chats(
            sentBy: sentBy,
            sentTo: sentTo
        )
        
        dbService.createChat(chat: chat) { documentID in
            completion()
        }
    }
}

class UserRegistrationViewModel: ObservableObject{
    private let dbService = DatabaseService()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    func registerUser(completion: @escaping () -> Void) {
        guard let uid = currentUserID else {
            print("エラー: ログインしていません")
            return
        }
        
        let user = User(
            id: uid
        )
        
        dbService.registerUser(user: user){ documentID in
            completion()
        }
    }
}
