//
//  OwnersItemView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/26.
//

import SwiftUI

struct OwnersItemView: View {
    let item: Item
    
    var body: some View {
        ZStack{
            VStack {
                if let url = URL(string: item.imageURL) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else if phase.error != nil {
                            Image(systemName: "photo.badge.exclamationmark")
                                .foregroundStyle(.gray)
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(height: 400)
                }
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
            .scrollEdgeEffectStyle(.soft, for: .top)
            
            Rectangle()
                .fill(.regularMaterial)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.0),
                            .init(color: .clear, location: 0.22)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea(edges: .top)
        }
        .safeAreaBar(edge: .top) {
            header
        }
        .toolbar{
            ToolbarItem(placement:.topBarTrailing){
                Button{}label:{
                    Image(systemName: "phone.badge.checkmark")
                        .foregroundStyle(.black)
                }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.teal.opacity(0.6))
            }
            
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            
            ToolbarItem(placement:.topBarTrailing){
                Button{}label: {
                    Image(systemName: "qrcode")
                        .foregroundStyle(Color.black)
                }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.yellow.opacity(0.3))
            }
        }
    }
    
    private var header: some View {
        HStack {
            Text(item.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.leading)
            Spacer()
        }
    }
}
