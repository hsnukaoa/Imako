//
//  ContactView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/01.
//

import SwiftUI

struct ContactView: View {
    @ObservedObject var vm: AuthViewModel
    
    var body: some View {
        VStack{
            Text("This is ContactView")
            
            Button{
                vm.signOut()
            }label: {
                Text("ログアウト")
                    .font(.callout.bold())
            }
            .padding()
            .background(Color.red)
            .foregroundStyle(.white)
            .clipShape(.capsule)
        }
    }
}

#Preview {
    let previewVM = AuthViewModel()
    ContactView(vm: previewVM)
}
