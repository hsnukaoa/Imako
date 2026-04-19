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
}

class ItemRegistrationViewModel: ObservableObject{
    @Published var isSaving = false
    private let dbService = DatabaseService()
    
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    func registerNewItem(name: String, image: UIImage, canCall: Bool, completion: @escaping () -> Void) {
        
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
                canCall: canCall
            )
            
            self.dbService.saveItem(item: newItem) { documentID in
                DispatchQueue.main.async {
                    self.isSaving = false
                    
                    if let id = documentID {
                        print("すべての保存が完了！QRコード用のID: \(id)")
                    }
                    
                    completion()
                }
            }
        }
    }
}
