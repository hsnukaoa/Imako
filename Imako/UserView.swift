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
    @Environment(\.openURL) private var openURL
    
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
                    
                    HStack{
                        Text("オープンソースライセンス：")
                        Spacer()
                    }
                    ScrollView {
                        Text("""
                                MIT License

                                Copyright (c) 2025 NOPROBLEM

                                Permission is hereby granted, free of charge, to any person obtaining a copy
                                of this software and associated documentation files (the "Software"), to deal
                                in the Software without restriction, including without limitation the rights
                                to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
                                copies of the Software, and to permit persons to whom the Software is
                                furnished to do so, subject to the following conditions:

                                The above copyright notice and this permission notice shall be included in all
                                copies or substantial portions of the Software.

                                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
                                IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
                                FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
                                AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
                                LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
                                OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
                                SOFTWARE.
                                """)
                        .font(.caption)
                        .padding()
                    }
                    .frame(maxHeight: 250)
                    .background(.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .navigationBarTitleDisplayMode(.inline)
                    
                    Spacer()
                    
                    HStack{
                        Text("開発者: yutianchuankouta@gmail.com")
                    }
                    .padding()
                    
                    Button{
                        openURL(URL(string: "https://bouncy-hockey-26d.notion.site/EULA-52e09fa640bd4b38ac4ee3f43488b230?source=copy_link")!)
                    }label: {
                        HStack{
                            Spacer()
                            Image(systemName: "info.circle")
                            Text("利用規約")
                            Spacer()
                        }
                        .foregroundStyle(.tint)
                    }
                    .buttonStyle(.plain)
                    
                    Button{
                        openURL(URL(string: "https://bouncy-hockey-26d.notion.site/cfeb82e2b6d84821b9d5bf1912629029?source=copy_link")!)
                    }label: {
                        HStack{
                            Spacer()
                            Image(systemName: "info.circle")
                            Text("プライバシーポリシー")
                            Spacer()
                        }
                        .foregroundStyle(.tint)
                    }
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
                    vm.signOut()
                }label: {
                    Text("ログアウト")
                }
            }
            
            ToolbarItem(placement: .secondaryAction){
                
                Button(role: .destructive){
                    showAlert = true
                }label: {
                    Text("アカウントを削除")
                        .foregroundStyle(.red)
                }
                .alert("アカウントを削除しますか？", isPresented: $showAlert) {
                    Button("削除", role: .destructive) {
                        Task {
                            await vm.deleteUser()
                        }
                    }
                    Button("キャンセル", role: .cancel) {}
                } message: {
                    Text("この操作は取り消すことができず、アカウントを完全に削除することになります")
                }
            }
        }
    }
}

#Preview {
    UserView()
}

