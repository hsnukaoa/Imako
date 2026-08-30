//
//  EditItemView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/08/29.
//

import SwiftUI
import DesignSystem

// 変更された項目を管理するための列挙型
enum ItemField: String {
    case name = "名称"
    case image = "写真"
    case canCall = "電話をかける設定"
}

struct EditItemView: View {
    let item: Item
    @Environment(\.dismiss) var dismiss
    
    // ViewModelを編集用のものに変更
    @StateObject private var viewModel = ItemEditViewModel()
    
    @State private var itemName: String
    @State private var canCall: Bool
    @State private var showPicker: Bool = false
    @State private var imageData: Data?
    
    // 画像の初期状態を保持
    @State private var initialImageData: Data?
    
    @State private var showErrorAlert: Bool = false
    @State private var alertMessage: String = ""
    
    init(item: Item) {
        self.item = item
        _itemName = State(initialValue: item.name)
        _canCall = State(initialValue: item.canCall)
    }
    
    // 変更があったかどうかを判定する算出プロパティ
    private var hasChanges: Bool {
        return !getChangedFields().isEmpty
    }
    
    // どの値が変更されたかを返す関数
    private func getChangedFields() -> [ItemField] {
        var changes: [ItemField] = []
        if itemName != item.name { changes.append(.name) }
        if imageData != initialImageData { changes.append(.image) }
        if canCall != item.canCall { changes.append(.canCall) }
        return changes
    }
    
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
                    
                    Text("持ち物を編集")
                        .font(.title3.bold())
                    
                    Spacer()
                    
                    Button{
                        guard let itemID = item.id else {
                            alertMessage = "アイテム情報にエラーがあります。"
                            showErrorAlert = true
                            return
                        }
                        
                        let changes = getChangedFields()
                        print("変更された項目: \(changes.map { $0.rawValue }.joined(separator: ", "))")
                        
                        // 変更された値だけをオプショナルで抽出
                        let updateName = changes.contains(.name) ? itemName : nil
                        let updateCanCall = changes.contains(.canCall) ? canCall : nil
                        
                        var updateImage: UIImage? = nil
                        if changes.contains(.image) {
                            if let data = imageData, let uiImage = UIImage(data: data) {
                                updateImage = uiImage
                            } else {
                                alertMessage = "画像の読み込みに失敗しました。"
                                showErrorAlert = true
                                return
                            }
                        }
                        
                        // ItemEditViewModelのeditItemを呼び出し（変更がない項目にはnilが渡される）
                        viewModel.editItem(
                            itemID: itemID,
                            name: updateName,
                            canCall: updateCanCall,
                            newImage: updateImage
                        ) { success in
                            if success {
                                dismiss()
                            } else {
                                alertMessage = "持ち物の更新に失敗しました。通信環境を確認のうえ、再度お試しください。"
                                showErrorAlert = true
                            }
                        }
                    }label: {
                        Image(systemName: "checkmark")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                    // ローディング状態（isUpdating）と変更有無（!hasChanges）でボタンを無効化
                    .disabled(itemName.isEmpty || viewModel.isUpdating || imageData == nil || !hasChanges)
                    .padding()
                    .glassEffect(.regular.tint(.blue).interactive(), in: .circle)
                    .buttonStyle(.plain)
                }
                .padding()
                
                VStack{
                    HStack{
                        Text("名称変更")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Divider()
                    
                    TextField("例：こうたのカバン", text: $itemName)
                }
                .padding()
                
                VStack{
                    HStack{
                        Text("写真を変更")
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
                            .buttonStyle(.plain)
                            .offset(x: 8, y: 8)
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                
                Spacer()
            }
            .blur(radius: viewModel.isUpdating ? 3 : 0)
            
            if viewModel.isUpdating {
                ZStack {
                    Rectangle()
                        .fill(Color.black.opacity(0.15))
                        .ignoresSafeArea()
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("更新中...")
                            .font(.body)
                            .bold()
                    }
                    .padding(30)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                }
            }
        }
        .imagePicker(isPresented: $showPicker, selectedImageData: $imageData)
        .alert("エラー", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .task {
            guard imageData == nil else { return }

            guard let urlString = (item.imageURL as Any?) as? String,
                  let url = URL(string: urlString) else {
                return
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                self.imageData = data
                self.initialImageData = data // 初期画像データとして保存
            } catch {
                print("画像の取得に失敗しました: \(error.localizedDescription)")
            }
        }
    }
}
