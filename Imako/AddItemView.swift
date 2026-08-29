//
//  AddItemView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/06.
//

import SwiftUI
import DesignSystem
import Combine

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ItemRegistrationViewModel()
    @State private var ItemName: String = ""
    @State private var canCall: Bool = false
    @State private var showPicker: Bool = false
    @State private var imageData: Data?
    
    @State private var showErrorAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        ZStack {
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
                    
                    Text("持ち物を追加")
                        .font(.title3.bold())
                    
                    Spacer()
                    
                    Button{
                        guard let data = imageData, let uiImage = UIImage(data: data) else {
                            alertMessage = "画像の読み込みに失敗しました。"
                            showErrorAlert = true
                            return
                        }
                        
                        viewModel.registerNewItem(name: ItemName, image: uiImage, canCall: canCall, lostNumber: 0) { success in
                            if success {
                                dismiss()
                            } else {
                                alertMessage = "持ち物の登録に失敗しました。通信環境を確認のうえ、再度お試しください。"
                                showErrorAlert = true
                            }
                        }
                    }label: {
                        Image(systemName: "checkmark")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                    .disabled(ItemName.isEmpty || viewModel.isSaving || imageData == nil)
                    .padding()
                    .glassEffect(.regular.tint(.blue).interactive(), in: .circle)
                    .buttonStyle(.plain)
                }
                .padding()
                
                VStack{
                    HStack{
                        Text("名前を入力")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Divider()
                    
                    TextField("例：こうたのカバン", text: $ItemName)
                }
                .padding()
                
                VStack{
                    HStack{
                        Text("写真を追加")
                            .font(.headline)
                        Spacer()
                    }
                    
                    HStack{
                        ZStack(alignment: .bottomTrailing) {
                            if let imageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 180)
                            }else{
                                Button{
                                    showPicker = true
                                } label: {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.black.opacity(0.65))
                                        .padding()
                                        .background(Color.blue.opacity(0))
                                }
                                .frame(width: 180, height: 180)
                                .background(Color.gray.opacity(0.25))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .buttonStyle(.plain)
                            }
                            
                            Button{
                                showPicker = true
                            } label: {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 25))
                                    .padding(13)
                                    .glassEffect(.regular, in: .circle)
                            }
                            .imagePicker(isPresented: $showPicker, selectedImageData: $imageData)
                            .buttonStyle(.plain)
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
                    
                    Text(canCall ? "重大な落とし物をしたときに、発見者があなたに電話をかけることができるようになります" : "")
                        .padding()
                        .font(.callout)
                }
                .padding()
                
                Spacer()
            }
            .blur(radius: viewModel.isSaving ? 3 : 0)
            
            if viewModel.isSaving {
                ZStack {
                    Rectangle()
                        .fill(Color.black.opacity(0.15))
                        .ignoresSafeArea()
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("保存中...")
                            .font(.body)
                            .bold()
                    }
                    .padding(30)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                }
            }
        }
        .alert("エラー", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

#Preview {
    AddItemView()
}
