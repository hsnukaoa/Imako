//
//  UserView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/08/17.
//

import SwiftUI
import FirebaseAuth

struct UserView: View {
    @StateObject var vm = AuthViewModel()
    let user = Auth.auth().currentUser
    @State private var showAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            if user?.uid != nil {
                VStack{
                    HStack{
                        Image(systemName: "person.circle")
                            .font(.largeTitle)
                        Text("ユーザー情報")
                            .font(.headline)
                        
                        Spacer()
                    }
                    .padding()
                    
                    HStack{
                        Text("UID: \(user?.uid ?? "None")")
                        Spacer()
                    }
                    .padding()
                    
                    HStack{
                        Text("メールアドレス:\(user?.email ?? "no email")")
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    HStack{
                        Text("アカウント作成: \(user?.metadata.creationDate?.formatted(date: .long, time: .omitted) ?? "アカウント未作成")")
                        
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button{
                        vm.signOut()
                    }label: {
                        Text("ログアウト")
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding()
                    .buttonStyle(.plain)
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    Text("エラー: ログインしていません")
                        .foregroundStyle(.white)
                        .font(.default.bold())
                        .padding()
                    NavigationLink{
                        LoginView(vm: vm)
                    }label: {
                        Text("ログイン")
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding()
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.red)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar{
            ToolbarItem(placement: .secondaryAction){
                Button{
                    showAlert = true
                }label: {
                    Text("アカウントを削除")
                        .foregroundStyle(.red)
                }
            }
        }
        .alert("アカウントを削除しますか？", isPresented: $showAlert) {
            Button("削除", role: .destructive) {
                vm.deleteUser()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この操作は取り消すことができず、アカウントを完全に削除することになります")
        }
    }
}

#Preview {
    UserView()
}
