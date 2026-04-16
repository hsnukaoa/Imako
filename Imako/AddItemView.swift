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
    @State private var canCall: Bool = false
    
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
                
                HStack{
                    ZStack(alignment: .bottomTrailing) {
                        
                        Button{
                            
                        } label: {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundStyle(.black.opacity(0.65))
                                .padding()
                        }
                        .frame(width: 180, height: 180)
                        .background(Color.gray.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        Button{
                            
                        } label: {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 25))
                                .foregroundStyle(.black)
                                .padding(13)
                                .glassEffect()
                                .clipShape(Circle())
                        }
                        .offset(x: 8, y: 8)
                    }
                    
                    Spacer()
                    
                }
            }
            .padding()
            
            VStack{
                HStack{
                    Spacer()
                    
                    Text("電話をかける")
                        .font(.headline)
                    
                    Toggle(isOn: $canCall) {}
                    Spacer()
                }
                .padding()
                
                Text(canCall ? "重要な落とし物をしたときに、発見者があなたに電話をかけることができるようになります" : "")
                    .padding()
                    .font(.callout)
            }
            .padding()
            
            Spacer()
        }
    }
}

#Preview {
    AddItemView()
}
