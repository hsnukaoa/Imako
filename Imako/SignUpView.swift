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
                        .background(Color.red)
                        .cornerRadius(25)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    let previewVM = AuthViewModel()
    SignUpView(vm: previewVM)
}
