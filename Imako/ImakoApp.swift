//
//  ImakoApp.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/01.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import FirebaseAuth
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // プッシュ通知の許可リクエスト
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                print("通知許可エラー: \(error.localizedDescription)")
            }
        }
        
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        
        return true
    }
    
    // APNsトークンをFCMに連携
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // フォアグラウンドでも通知を表示 (カッコを修正)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // FCMトークンの取得・更新時にFirestoreへ保存
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        
        // テスト送信用に最新のトークンを出力
        print("====== これがFCMトークンです ======")
        print(token)
        print("====================================")
        
        // ログイン済みの場合のみFirestoreに保存
        if let uid = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            db.collection("users").document(uid).setData(["fcmToken": token], merge: true)
        } else {
            print("未ログインのためFirestoreへの保存をスキップしました")
        }
    }
}

@main
struct ImakoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var vm = AuthViewModel()
    @StateObject var chatListVM = ChatListViewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                if vm.isLoggedIn {
                    ContentView(vm: vm, chatListVM: chatListVM)
                } else {
                    LoginView(vm: vm)
                }
            }
        }
    }
}
