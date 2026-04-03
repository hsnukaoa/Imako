//
//  ImakoApp.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/01.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate{
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool{
        FirebaseApp.configure()
        return true
    }
}

@main
struct ImakoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var vm = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationView{
                if vm.isLoggedIn {
                    ContentView(vm: vm)
                } else {
                    LoginView(vm: vm)
                }
            }
        }
    }
}
