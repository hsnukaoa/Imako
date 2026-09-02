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
    @Published var isBlock: Bool = false
    @Published var isBlockedByOther: Bool = false
    @Published var isMuted: Bool = false
    
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
                
                let visibleTo = data["visibleTo"] as? [String] ?? []
                let blockedBy = data["blockedBy"] as? [String] ?? []
                let mutedBy = data["mutedBy"] as? [String] ?? []
                
                DispatchQueue.main.async {
                    self.isBlock = blockedBy.contains(currentUID)
                    self.isBlockedByOther = !visibleTo.contains(currentUID)
                    self.isMuted = mutedBy.contains(currentUID)
                }
            }
    }
    
    //ミュート機能
    func toggleMute(chatID: String, currentUserID: String, isCurrentlyMuted: Bool) async {
        let chatRef = db.collection("chats").document(chatID)
        do {
            if isCurrentlyMuted {
                try await chatRef.updateData([
                    "mutedBy": FieldValue.arrayRemove([currentUserID])
                ])
            } else {
                try await chatRef.updateData([
                    "mutedBy": FieldValue.arrayUnion([currentUserID])
                ])
            }
        } catch {
        }
    }
    
    func blockAndReport(targetUserID: String, currentUserID: String, chatID: String) async {
        let toEmail = "yutianchuankouta@gmail.com"
        let subject = "【いまこ】悪質なユーザーの報告"
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
        }
    }
    
    func stopListening() {
        listener?.remove()
    }
    
    deinit {
        stopListening()
    }
}
