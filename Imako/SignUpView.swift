//
//  SignUpView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/03.
//

import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isAgreed = false
    
    @ObservedObject var vm: AuthViewModel
    
    var body: some View {
        NavigationStack{
            VStack {
                Spacer()
                Text("新規登録")
                    .font(.largeTitle.bold())
                
                Spacer()
                
                VStack{
                    HStack{
                        Text("メールアドレス")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Divider()
                    
                    TextField("メールアドレスを入力", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                .padding()
                
                VStack{
                    HStack{
                        Text("パスワード")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Divider()
                    SecureField("パスワードを入力", text: $password)
                }
                .padding()
                
                VStack{
                    HStack{
                        Text("パスワードの確認")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Divider()
                    SecureField("もう一度パスワードを入力", text: $confirmPassword)
                }
                .padding()
                
                if let error = vm.errorMessage {
                    Text(error).foregroundColor(.red)
                }
                
                Spacer()
                Spacer()
                
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: {
                        isAgreed.toggle()
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: isAgreed ? "checkmark.square.fill" : "square")
                                .foregroundColor(isAgreed ? .red : .gray)
                                .font(.title3)
                            
                            Text("以下の利用規約とプライバシーポリシーに同意します。")
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    HStack(spacing: 16) {
                        Link("利用規約 (EULA)", destination: URL(string: "https://bouncy-hockey-26d.notion.site/EULA-52e09fa640bd4b38ac4ee3f43488b230?source=copy_link")!)
                            .font(.footnote.bold())
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                            .padding(.trailing, 8)
                            .buttonStyle(.plain)
                        
                        Link("プライバシーポリシー", destination: URL(string: "https://bouncy-hockey-26d.notion.site/cfeb82e2b6d84821b9d5bf1912629029?source=copy_link")!)
                            .font(.footnote.bold())
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                            .buttonStyle(.plain)
                    }
                    .padding(.leading, 28)
                    
                    Text("※当アプリでは、誹謗中傷や不適切なコンテンツの投稿を固く禁じます。違反したユーザーはアカウント停止などの措置を行います。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 15)
                
                Button {
                    if password != confirmPassword {
                        vm.errorMessage = "パスワードが一致しません"
                        return
                    }
                    
                    vm.signUp(email: email, password: password)
                    
                }label: {
                    Text("アカウント作成")
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: 360)
                        .background(isAgreed ? Color.red : Color.gray)
                        .cornerRadius(25)
                }
                .buttonStyle(.plain)
                .disabled(!isAgreed)
                
                Spacer()
            }
            .padding()
            .onAppear{
                vm.errorMessage = nil
            }
        }
    }
}

#Preview {
    let previewVM = AuthViewModel()
    SignUpView(vm: previewVM)
}
