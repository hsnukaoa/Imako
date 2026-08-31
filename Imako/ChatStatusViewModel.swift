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
    
    // MARK: - ミュート機能
    func toggleMute(chatID: String, currentUserID: String, isCurrentlyMuted: Bool) async {
        let chatRef = db.collection("chats").document(chatID)
        do {
            if isCurrentlyMuted {
                // ミュート解除
                try await chatRef.updateData([
                    "mutedBy": FieldValue.arrayRemove([currentUserID])
                ])
            } else {
                // ミュートする
                try await chatRef.updateData([
                    "mutedBy": FieldValue.arrayUnion([currentUserID])
                ])
            }
        } catch {
            print("ミュート設定の変更に失敗しました: \(error.localizedDescription)")
        }
    }
    
    // MARK: - ブロックして報告機能
    // ※ 既存のブロック処理を呼んだ後、指定のGmail宛にメールを作成する画面を立ち上げます
    func blockAndReport(targetUserID: String, currentUserID: String, chatID: String) async {
        // 1. 既存のブロック処理を実行 (仮に blockUser() というメソッドがある前提)
        // await blockUser(targetUserID: targetUserID, currentUserID: currentUserID, chatID: chatID)
        
        // 2. メールアプリを立ち上げる (mailtoスキームを利用)
        let toEmail = "yutianchuankouta@gmail.com"
        let subject = "【Imako】悪質なユーザーの報告"
        let body = """
            運営チーム様
            
            以下のユーザーについて報告します。
            
            ・報告対象のユーザーID: \(targetUserID)
            ・チャットID: \(chatID)
            ・報告者のユーザーID: \(currentUserID)
            
            【報告の理由を以下に記載してください】
            
            """
        
        guard let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "mailto:\(toEmail)?subject=\(encodedSubject)&body=\(encodedBody)") else {
            return
        }
        
        // メールアプリを開く
        if UIApplication.shared.canOpenURL(url) {
            await UIApplication.shared.open(url)
        } else {
            print("メールアプリが設定されていません")
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
