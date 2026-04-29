//
//  ItemView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/01.
//

import SwiftUI

struct ItemView: View {
    @State private var showSheet = false
    @StateObject private var viewModel = ItemListViewModel()
    
    let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]
    
    var body: some View {
        Group {
            if viewModel.items.isEmpty {
                VStack {
                    headerView
                    
                    Spacer()
                    Image(systemName: "square.stack.3d.up.slash")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.tint)
                    Text("持ち物はありません")
                        .font(.title)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.items) { item in
                            ItemCard(item: item)
                        }
                    }
                    .padding()
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
                .safeAreaBar(edge: .top) {
                    headerView
                }
            }
        }
        .sheet(isPresented: $showSheet) {
            AddItemView()
        }
        .onAppear {
            viewModel.fetchItems()
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("持ち物")
                .font(.largeTitle.bold())
                .padding()
            
            Spacer()
            
            Button {
                showSheet = true
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(.black)
                    .font(.title)
                    .padding()
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct ItemCard: View {
    let item: Item
    
    var body: some View {
        NavigationLink(destination: BranchDetailView(item: item)) {
            HStack {
                if let url = URL(string: item.imageURL) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable()
                                .scaledToFill()
                        } else if phase.error != nil {
                            Image(systemName: "photo.badge.exclamationmark")
                                .foregroundStyle(.gray)
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(width: 100, height: 165)
                }
                
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                    .padding()
                
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.background)
                    .shadow(color: Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1)), radius: 4, x: 2, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.black, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ItemView()
}
