//
//  ShowQRView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/05/02.
//

import SwiftUI

struct ShowQRView: View {
    let item: Item
    @Environment(\.dismiss) var dismiss
    
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
                .glassEffect(.regular.interactive(), in: .circle)
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding()
            
            Spacer()
            
            Text("\(item.name)のQRコード")
                .font(.title2.bold())
                .padding()
            QrCodeView(item: item)
                .frame(maxWidth: 200, maxHeight: 200)
                .padding()
            
            
            Spacer()
            Spacer()
        }
    }
}
