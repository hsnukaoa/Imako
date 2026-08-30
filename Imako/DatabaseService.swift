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
import FirebaseFunctions

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
    
    func blockUser(chatID: String, currentUserID: String, targetUserID: String, completion: @escaping (Bool) -> Void) {
        let batch = db.batch()
        
        // blockedByに自分を追加し、visibleToから相手を削除
        let chatRef = db.collection("chats").document(chatID)
        batch.updateData([
            "blockedBy": FieldValue.arrayUnion([currentUserID]),
            "visibleTo": FieldValue.arrayRemove([targetUserID])
        ], forDocument: chatRef)
        
        // ドキュメントIDをブロック相手のuidに指定
        let blockedUserRef = db.collection("users")
            .document(currentUserID)
            .collection("blockedUser")
            .document(targetUserID)
        
        batch.setData(["blockedAt": FieldValue.serverTimestamp()], forDocument: blockedUserRef)
        
        // バッチ処理の実行
        batch.commit { error in
            if let error = error {
                print("Firebaseブロック処理エラー: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // DatabaseService.swift 内に追加
    
    func unblockUser(chatID: String, currentUserID: String, targetUserID: String, completion: @escaping (Bool) -> Void) {
        let batch = db.batch()
        
        // 1. chatsコレクションの更新
        // blockedByから自分を削除し、visibleToに相手を戻す（追加する）
        let chatRef = db.collection("chats").document(chatID)
        batch.updateData([
            "blockedBy": FieldValue.arrayRemove([currentUserID]),
            "visibleTo": FieldValue.arrayUnion([targetUserID])
        ], forDocument: chatRef)
        
        // 2. usersコレクションのサブコレクションから該当ドキュメントを削除
        let blockedUserRef = db.collection("users")
            .document(currentUserID)
            .collection("blockedUser")
            .document(targetUserID)
        
        batch.deleteDocument(blockedUserRef)
        
        // バッチ処理の実行
        batch.commit { error in
            if let error = error {
                print("Firebaseブロック解除処理エラー: \(error)")
                completion(false)
            } else {
                completion(true)
            }
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
        
        ImageService.uploadToCloudinary(image: image) { [weak self] result in
            guard let self = self else { return }
            
            guard let result = result else {
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
                imageURL: result.url,
                canCall: canCall,
                lostNumber: lostNumber ?? 0,
                imagePublicId: result.publicId
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

//メッセージを関連の関数
class MessageViewModel: ObservableObject {
    private let dbService = DatabaseService()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    func sendMessage(content: String, chatID: String,contentType: String,imagePublicId: String?, completion: @escaping (Bool) -> Void) {
        guard let uid = currentUserID else {
            print("エラー: ログインしていません")
            completion(false)
            return
        }
        
        let message = Message(
            content: content,
            senderID: uid,
            contentType: contentType,
            imagePublicId: imagePublicId
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
    
    func unsendMessage(message: Message, chat: Chats) async {
        let db = Firestore.firestore()
        lazy var functions = Functions.functions(region: "asia-northeast1")
        
        if message.contentType == "image", let publicId = message.imagePublicId {
            do {
                let result = try await functions.httpsCallable("deleteCloudinaryImage").call(["publicId": publicId])
                print("Cloudinary画像の削除成功: \(result.data)")
            } catch {
                print("Cloudinary画像の削除失敗: \(error)")
            }
        } else if message.contentType == "image" {
            print("imagePublicIdがnilのため、Cloudinary画像の削除をスキップします")
        }
        
        guard let messageId = message.id else { return }
        guard let chatId = chat.id else { return }
        let messageRef = db.collection("chats").document(chatId).collection("messages").document(messageId)
        
        do {
            try await messageRef.updateData([
                "contentType": "Delete",
                "content": FieldValue.delete(),
                "imagePublicId": FieldValue.delete()
            ])
            print("メッセージの送信取り消し（Firestore更新）完了")
        } catch {
            print("Firestoreの更新失敗: \(error)")
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
    
    func editItem(
        itemID: String,
        name: String? = nil,
        canCall: Bool? = nil,
        lostNumber: Int? = nil,
        newImage: UIImage? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        isUpdating = true
        
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
        
        if let imageToUpload = newImage {
            ImageService.uploadToCloudinary(image: imageToUpload) { [weak self] result in
                guard let self = self, let result = result else {
                    print("画像アップロード失敗")
                    DispatchQueue.main.async {
                        self?.isUpdating = false
                        completion(false)
                    }
                    return
                }
                
                updatedData["imageURL"] = result.url
                
                updatedData["imagePublicId"] = result.publicId
                
                self.saveChanges(itemID: itemID, updatedData: updatedData, completion: completion)
            }
        }
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

class ChatActionViewModel: ObservableObject {
    @Published var isProcessing = false
    private let dbService = DatabaseService()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    func blockUser(chat: Chats, completion: @escaping (Bool) -> Void) {
        guard let currentUID = currentUserID, let chatID = chat.id else {
            completion(false)
            return
        }
        
        isProcessing = true
        
        // ブロックする相手のUIDを特定 (sentByが自分ならsentToが相手、逆も然り)
        let targetUID = (chat.sentBy == currentUID) ? chat.sentTo : chat.sentBy
        
        dbService.blockUser(chatID: chatID, currentUserID: currentUID, targetUserID: targetUID) { [weak self] success in
            DispatchQueue.main.async {
                self?.isProcessing = false
                completion(success)
            }
        }
    }
    
    // ChatActionViewModel.swift 内に追加
    
    func unblockUser(chat: Chats, completion: @escaping (Bool) -> Void) {
        guard let currentUID = currentUserID, let chatID = chat.id else {
            completion(false)
            return
        }
        
        isProcessing = true
        let targetUID = (chat.sentBy == currentUID) ? chat.sentTo : chat.sentBy
        
        dbService.unblockUser(chatID: chatID, currentUserID: currentUID, targetUserID: targetUID) { [weak self] success in
            DispatchQueue.main.async {
                self?.isProcessing = false
                completion(success)
            }
        }
    }
}
