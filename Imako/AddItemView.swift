//
//  AddItemView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/06.
//

import SwiftUI

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    @State private var ItemName: String = ""
    
    var body: some View {
        
        VStack{
            HStack{
                Button{
                    dismiss()
                }label: {
                    Image(systemName: "multiply")
                        .foregroundStyle(.black)
                        .font(.title2)
                }
                .padding()
                .glassEffect()
                
                Spacer()
                
                Text("持ち物を追加")
                    .font(.headline)
                
                Spacer()
                
                
                Button{
                    dismiss()
                }label: {
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding()
                }
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.7))
                        .background(.ultraThinMaterial)
                )
                .clipShape(Capsule())
                .foregroundStyle(.primary)
            }
            .padding()
            
            VStack{
                HStack{
                    Text("名前を入力")
                        .font(.title3)
                    Spacer()
                }
                
                Divider()
                
                TextField("例：こうたのカバン", text: $ItemName)
            }
            .padding()
            
            VStack{
                HStack{
                    Text("写真を追加")
                        .font(.title3)
                    Spacer()
                }
                
            }
            .padding()
            
            Spacer()
        }
    }
}

#Preview {
    AddItemView()
}
