//
//  OwnersItemView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/26.
//

import SwiftUI

struct OwnersItemView: View {
    @State var item: Item
    private let dbservice = DatabaseService()
    
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
                    .frame(height: 450)
                    .clipped()
                }
                
                HStack{
                    Text("なくした回数:\(String(item.lostNumber ?? 0))")
                        .font(.title.bold())
                        .padding()
                    Spacer()
                }
                .padding()
                
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
        .safeAreaBar(edge: .bottom) {
            footer
                .padding()
        }
        .toolbar{
            ToolbarItem(placement:.topBarTrailing){
                Button{
                    item.canCall.toggle()
                    
                    if let itemID = item.id {
                        dbservice.updateCanCall(itemID: itemID, canCall: item.canCall)
                    }
                }label:{
                    Image(systemName: "phone.badge.checkmark")
                        .foregroundStyle(.black)
                }
                .buttonStyle(.borderedProminent)
                .tint(item.canCall ? Color.teal.opacity(0.6) : Color.gray.opacity(0.3))
                .id(item.canCall)
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
    
    private var footer: some View {
        HStack{
            Spacer()
            Button{
            }label: {
                Image(systemName: "square.and.pencil")
                    .font(.title2)
            }
            .padding()
            .glassEffect(.regular.interactive(), in: .circle)
            .buttonStyle(.plain)
        }
    }
}
