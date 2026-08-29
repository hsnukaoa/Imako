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
    
    // 指定したアイテムの情報を更新する関数
    func updateItem(itemID: String, updatedData: [String: Any], completion: @escaping (Bool) -> Void) {
        db.collection("items").document(itemID).updateData(updatedData) { error in
            if let error = error {
                print("Firebaseアイテム更新エラー: \(error)")
                completion(false)
            } else {
                completion(true)
            }
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
    
    func updateItemChatsArray(itemID: String, chatID: String) {
        db.collection("items").document(itemID).updateData([
            "chats": FieldValue.arrayUnion([chatID])
        ]) { error in
            if let error = error {
                print("Firebase更新エラー: \(error)")
            }
        }
    }
    
    func updateUserChatsArray(finderID: String, dropperID: String, chatID: String){
        db.collection("users").document(finderID).updateData([
            "chats": FieldValue.arrayUnion([chatID])
        ]) { error in
            if let error = error {
                print("Firebase更新エラー: \(error)")
            }
        }
        db.collection("users").document(dropperID).updateData([
            "chats": FieldValue.arrayUnion([chatID])
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

//チャットを作成するクラス
class ChatCreateViewModel: ObservableObject {
    private let dbService = DatabaseService()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    func searchSameChat(sentBy: String, sentTo: String, item: Item) async -> (exists: Bool, chat: Chats?) {
        guard currentUserID != nil else {
            print("エラー: ログインしていません")
            return (false, nil)
        }
        
        guard let itemID = item.id else {
            print("エラー: item.idが存在しません")
            return (false, nil)
        }
        
        let db = Firestore.firestore()
        
        do {
            let snapshot = try await db.collection("chats")
                .whereField("sentBy", isEqualTo: sentBy)
                .whereField("sentTo", isEqualTo: sentTo)
                .whereField("itemID", isEqualTo: itemID)
                .limit(to: 1)
                .getDocuments()
            
            if let document = snapshot.documents.first {
                if let chat = try? document.data(as: Chats.self) {
                    return (true, chat)
                } else {
                    print("エラー: Chats型へのデコードに失敗しました")
                    return (false, nil)
                }
            } else {
                return (false, nil)
            }
        } catch {
            print("エラー: 既存チャットの検索に失敗しました: \(error.localizedDescription)")
            return (false, nil)
        }
    }
    
    func createChat(sentBy: String, sentTo: String, item: Item, completion: @escaping (Bool, String?) -> Void) {
        guard currentUserID != nil else {
            print("エラー: ログインしていません")
            completion(false, nil)
            return
        }
        
        let chat = Chats(
            sentBy: sentBy,
            sentTo: sentTo,
            item: item
        )
        
        self.dbService.createChat(chat: chat) { documentID in
            DispatchQueue.main.async {
                if documentID != nil {
                    completion(true, documentID)
                } else {
                    completion(false, nil)
                }
            }
        }
    }
    
    func UpdateItemArray(chatID: String,itemID: String, completion: @escaping (Bool) -> Void) {
        self.dbService.updateItemChatsArray(itemID: itemID, chatID: chatID)
    }
    
    func UpdateUserArray(chatID: String, finderID: String, dropperID: String, completion: @escaping (Bool) -> Void){
        self.dbService.updateUserChatsArray(finderID: finderID, dropperID: dropperID, chatID: chatID)
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

//メッセージを送信する関数
class SendMessageViewModel: ObservableObject {
    private let dbService = DatabaseService()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    func sendMessage(content: String, chatID: String,contentType: String, completion: @escaping (Bool) -> Void) {
        guard let uid = currentUserID else {
            print("エラー: ログインしていません")
            completion(false)
            return
        }
        
        let message = Message(
            content: content,
            senderID: uid,
            contentType: contentType
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

//持ち物を削除する関数（画像削除はバックグラウンドでFirebaseFunctionsが実行）
class ItemDeleteViewModel: ObservableObject {
    func deleteItem(documentID: String) async {
        let db = Firestore.firestore()
        do {
            try await db.collection("items").document(documentID).delete()
        } catch {
            print("ドキュメントの削除に失敗しました: \(error)")
        }
    }
}

//Chatを削除する関数（サブコレクションの削除、user配列の組み直しはFirebaseFunctionsが実行）
class ChatsDeleteViewModel: ObservableObject {
    func deleteChat(chatId: String) async throws {
        let db = Firestore.firestore()
        let chatRef = db.collection("chats").document(chatId)
        try await chatRef.delete()
    }
}

class ItemEditViewModel: ObservableObject {
    @Published var isUpdating = false
    private let dbService = DatabaseService()
    
    /// アイテム情報を編集する関数（値がある項目のみ更新）
    func editItem(
        itemID: String,
        name: String? = nil,
        canCall: Bool? = nil,
        lostNumber: Int? = nil,
        newImage: UIImage? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        isUpdating = true
        
        // 1. 更新用の辞書を動的に作成（値が存在するものだけ追加）
        var updatedData: [String: Any] = [:]
        
        if let newName = name {
            updatedData["name"] = newName
        }
        if let newCanCall = canCall {
            updatedData["canCall"] = newCanCall
        }
        if let newLostNumber = lostNumber {
            updatedData["lostNumber"] = newLostNumber
        }
        
        // 2. 画像の変更がある場合
        if let imageToUpload = newImage {
            ImageService.uploadToCloudinary(image: imageToUpload) { [weak self] imageUrlString in
                guard let self = self, let urlString = imageUrlString else {
                    print("画像アップロード失敗")
                    DispatchQueue.main.async {
                        self?.isUpdating = false
                        completion(false)
                    }
                    return
                }
                
                // 画像URLを辞書に追加
                updatedData["imageURL"] = urlString
                
                // Itemのinitと同じロジックで publicId を抽出して辞書に追加
                if let url = URL(string: urlString) {
                    let publicId = url.deletingPathExtension().lastPathComponent
                    updatedData["imagePublicId"] = publicId
                }
                
                self.saveChanges(itemID: itemID, updatedData: updatedData, completion: completion)
            }
        }
        // 3. 画像の変更がない場合
        else {
            guard !updatedData.isEmpty else {
                print("更新するデータがありません")
                DispatchQueue.main.async {
                    self.isUpdating = false
                    completion(true)
                }
                return
            }
            
            self.saveChanges(itemID: itemID, updatedData: updatedData, completion: completion)
        }
    }
    
    // Firestoreへの保存処理をまとめたプライベート関数
    private func saveChanges(itemID: String, updatedData: [String: Any], completion: @escaping (Bool) -> Void) {
        // ※ DatabaseServiceに前述の updateItem 関数が追加されている前提です
        dbService.updateItem(itemID: itemID, updatedData: updatedData) { [weak self] success in
            DispatchQueue.main.async {
                self?.isUpdating = false
                completion(success)
            }
        }
    }
}
