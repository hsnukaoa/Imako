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
                self.viewModel.registerUser { success in }
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
            print("退会処理を開始します...")
            let result = try await functions.httpsCallable("deleteAccount").call()
            
            if let data = result.data as? [String: Any],
               let message = data["message"] as? String {
                print("サーバー処理成功: \(message)")
            }
            
            try Auth.auth().signOut()
            print("アプリのサインアウトが完了しました。")
            
        } catch {
            print("退会処理に失敗しました: \(error.localizedDescription)")
            
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let code = FunctionsErrorCode(rawValue: error.code)
                    let details = error.userInfo[FunctionsErrorDetailsKey]
                    print("Functionsエラーコード: \(String(describing: code))")
                    print("エラー詳細: \(String(describing: details))")
                }
            }
        }
    }
}
