//
//  ChatStatusViewModel.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/08/30.
//


import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Combine

class ChatStatusViewModel: ObservableObject {
    // ユーザー要望のフラグ
    @Published var isBlock: Bool = false          // 自分がブロックしているか (blockedBy)
    @Published var isBlockedByOther: Bool = false // 相手からブロックされたか (visibleTo)
    
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    // リアルタイム監視の開始
    func listenToChatStatus(chatID: String) {
        guard let currentUID = currentUserID else { return }
        
        // chatsドキュメントをリアルタイムリスナーで監視
        listener = db.collection("chats").document(chatID)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self,
                      let document = documentSnapshot,
                      document.exists,
                      let data = document.data() else { return }
                
                // 配列を取得（nilの場合は空配列）
                let visibleTo = data["visibleTo"] as? [String] ?? []
                let blockedBy = data["blockedBy"] as? [String] ?? []
                
                DispatchQueue.main.async {
                    // ① 自分が blockedBy に含まれていれば「自分がブロックしている(isBlock)」
                    self.isBlock = blockedBy.contains(currentUID)
                    
                    // ② 自分が visibleTo に含まれていなければ「相手からブロックされた」
                    self.isBlockedByOther = !visibleTo.contains(currentUID)
                }
            }
    }
    
    // 画面が閉じられたら監視を解除（メモリリーク防止）
    func stopListening() {
        listener?.remove()
    }
    
    deinit {
        stopListening()
    }
}
