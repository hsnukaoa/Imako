//
//  DatabaseService.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/19.
//

import Foundation
import FirebaseFirestore
import Combine
import FirebaseAuth
import UIKit

class DatabaseService {
    private let db = Firestore.firestore()
    
    func saveItem(item: Item, completion: @escaping (String?) -> Void) {
        do {
            let ref = try db.collection("items").addDocument(from: item)
            completion(ref.documentID)
        } catch {
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
    
    func createChat(chat: Chats, completion: @escaping (String?) -> Void) {
        do {
            let ref = try db.collection("chats").addDocument(from: chat)
            completion(ref.documentID)
        } catch {
            print("Firebaseチャット作成エラー: \(error)")
            completion(nil)
        }
    }
    
    func registerUser(user: AppUser, completion: @escaping (String?) -> Void) {
        do {
            try db.collection("users").document(user.uid!).setData(from: user)
            completion(user.uid)
        } catch {
            print("Firebaseユーザー登録エラー: \(error)")
            completion(nil)
        }
    }
    
    func sendMessage(message: Message, chatID: String, completion: @escaping (String?) -> Void) {
        do {
            let ref = try db.collection("chats").document(chatID).collection("messages").addDocument(from: message)
            completion(ref.documentID)
        } catch {
            print("Firebaseメッセージ送信エラー: \(error)")
            completion(nil)
        }
    }
}

class ItemRegistrationViewModel: ObservableObject {
    @Published var isSaving = false
    private let dbService = DatabaseService()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    func registerNewItem(name: String, image: UIImage, canCall: Bool, lostNumber: Int?, completion: @escaping (Bool) -> Void) {
        
        guard let uid = currentUserID else {
            print("エラー: ログインしていません")
            completion(false)
            return
        }
        
        isSaving = true
        
        ImageService.uploadToCloudinary(image: image) { [weak self] imageUrl in
            guard let self = self else { return }
            
            guard let url = imageUrl else {
                print("画像アップロード失敗")
                DispatchQueue.main.async {
                    self.isSaving = false
                    completion(false)
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
                    if documentID != nil {
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
        }
    }
}

class ChatCreateViewModel: ObservableObject {
    private let dbService = DatabaseService()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    func createChat(sentBy: String, sentTo: String, completion: @escaping (Bool) -> Void) {
        guard currentUserID != nil else {
            print("エラー: ログインしていません")
            completion(false)
            return
        }
        
        let chat = Chats(
            sentBy: sentBy,
            sentTo: sentTo
        )
        
        dbService.createChat(chat: chat) { documentID in
            DispatchQueue.main.async {
                if documentID != nil {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
}

class UserRegistrationViewModel: ObservableObject {
    private let dbService = DatabaseService()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    func registerUser(completion: @escaping (Bool) -> Void) {
        guard let uid = currentUserID else {
            completion(false)
            return
        }
        
        let user = AppUser(uid: uid)
        
        dbService.registerUser(user: user) { documentID in
            DispatchQueue.main.async {
                if documentID != nil {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
}

class SendMessageViewModel: ObservableObject {
    private let dbService = DatabaseService()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    func sendMessage(content: String, chatID: String, completion: @escaping (Bool) -> Void) {
        guard let uid = currentUserID else {
            print("エラー: ログインしていません")
            completion(false)
            return
        }
        
        let message = Message(
            content: content,
            senderID: uid
        )
        
        dbService.sendMessage(message: message, chatID: chatID) { documentID in
            DispatchQueue.main.async {
                if documentID != nil {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
}
