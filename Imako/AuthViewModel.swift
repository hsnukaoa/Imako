//
//  AuthViewModel.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/01.
//

import FirebaseAuth
import SwiftUI
import Combine

class AuthViewModel: ObservableObject{
    @Published var isLoggedIn = false
    @Published var errorMessage: String?
    
    init(){
        isLoggedIn = Auth.auth().currentUser != nil
    }
    
    func signUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                } else {
                    self.isLoggedIn = true
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
                self.isLoggedIn = true
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isLoggedIn = false
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
