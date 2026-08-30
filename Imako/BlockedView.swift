//
//  BlockedView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/08/30.
//

import SwiftUI

struct BlockedView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "nosign")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("このチャットは現在利用できません")
                .font(.title3)
                .bold()
            
            // 閉じるボタン（フルスクリーンカバーを閉じる用）
            Button {
                dismiss()
            } label: {
                Text("戻る")
                    .fontWeight(.semibold)
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}
