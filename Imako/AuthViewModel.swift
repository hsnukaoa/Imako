//
//  AuthViewModel.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/01.
//

import FirebaseAuth
import SwiftUI
import Combine
import FirebaseFunctions
import FirebaseMessaging
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var errorMessage: String?
    private var viewModel = UserRegistrationViewModel()
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isLoggedIn = (user != nil)
            }
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                // ユーザー登録処理の完了後にトークンを保存
                self.viewModel.registerUser { success in
                    guard success else { return }
                    
                    Messaging.messaging().token { token, _ in
                        if let token = token, let uid = Auth.auth().currentUser?.uid {
                            let db = Firestore.firestore()
                            db.collection("users").document(uid).setData(["fcmToken": token], merge: true)
                        }
                    }
                }
            }
        }
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                Messaging.messaging().token { token, error in
                    if error != nil {
                        return
                    }
                    if let token = token, let uid = Auth.auth().currentUser?.uid {
                        let db = Firestore.firestore()
                        db.collection("users").document(uid).setData(["fcmToken": token], merge: true)
                    }
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func deleteUser() async {
        let functions = Functions.functions(region: "asia-northeast1")
        
        do {
            _ = try await functions.httpsCallable("deleteAccount").call()
            
            try Auth.auth().signOut()
            
        } catch {
        }
    }
}
