//
//  ItemView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/01.
//

import SwiftUI

struct ItemView: View {
    @State private var showSheet = false
    
    var body: some View {
        VStack{
            HStack {
                Text("持ち物")
                    .font(.largeTitle.bold())
                    .padding()
                
                Spacer()
                
                
                Button{
                    showSheet = true
                }label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.black)
                        .font(.title)
                        .padding()
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)
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
        .sheet(isPresented: $showSheet){
            AddItemView()
        }
    }
}

#Preview {
    ItemView()
}
