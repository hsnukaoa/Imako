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
                    self.errorMessage = self.translateAuthError(error)
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
                    self.errorMessage = self.translateAuthError(error)
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
            self.errorMessage = self.translateAuthError(error)
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
    
    private func translateAuthError(_ error: Error) -> String {
        let nsError = error as NSError
        
        if let errorCode = AuthErrorCode(rawValue: nsError.code) {
            switch errorCode {
            case .invalidEmail:
                return "メールアドレスの形式が正しくありません。"
            case .emailAlreadyInUse:
                return "このメールアドレスは既に登録されています。"
            case .weakPassword:
                return "パスワードは6文字以上で入力してください。"
            case .userNotFound:
                return "ユーザーが見つかりません。登録したメールアドレスを確認してください。"
            case .wrongPassword:
                return "パスワードが間違っています。"
            case .networkError:
                return "通信エラーが発生しました。電波の良い所で再度お試しください。"
            case .tooManyRequests:
                return "アクセスが集中しているか、試行回数が多すぎます。しばらく経ってから再度お試しください。"
            case .invalidCredential:
                return "メールアドレスまたはパスワードが間違っています。"
            default:
                break
            }
        }
        
        return "エラーが発生しました。(\(error.localizedDescription))"
    }
}
