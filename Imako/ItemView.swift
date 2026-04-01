//
//  ItemView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/01.
//

import SwiftUI

struct ItemView: View {
    var body: some View {
        VStack{
            HStack {
                Text("持ち物")
                    .font(.largeTitle.bold())
                    .padding()
                
                Spacer()
                
                
                Button{
                    /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/ /*@END_MENU_TOKEN@*/
                }label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.black)
                        .font(.title)
                }
                .padding()
                .glassEffect()
            }
            .padding()
            
            Spacer()
            
            Image(systemName: "square.stack.3d.up.slash")
                .font(.largeTitle.bold())
                .foregroundStyle(.tint)
            Text("持ち物はありません")
                .font(.title)
            
            Spacer()
        }
    }
}

#Preview {
    ItemView()
}
