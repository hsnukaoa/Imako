//
//  LoginView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/01.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    
    @ObservedObject var vm: AuthViewModel
    
    var body: some View {
        NavigationStack{
            VStack {
                Spacer()
                Spacer()
                Text("ログイン")
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
                    SecureField("パスワード", text: $password)
                }
                .padding()
                
                if let error = vm.errorMessage {
                    Text(error).foregroundColor(.red)
                }
                
                Spacer()
                Spacer()
                
                Button {
                    vm.signIn(email: email, password: password)
                }label: {
                    Text("ログイン")
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: 360)
                        .background(Color.black)
                        .cornerRadius(25)
                }
                
                HStack{
                    Text("または")
                        .font(.callout.bold())
                    
                    NavigationLink(destination: SignUpView(vm: vm)){
                        Text("新規登録")
                            .font(.callout.bold())
                            .foregroundStyle(.red)
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    let previewVM = AuthViewModel()
    return LoginView(vm: previewVM)
}
