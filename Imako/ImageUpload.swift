//
//  ImageUpload.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/19.
//

import Foundation
import UIKit
import Cloudinary

class ImageService {
    static let cloudinary = CLDCloudinary(configuration: CLDConfiguration(cloudName: "dytxyrksy", secure: true))
    
    static let uploadPreset = "imaco_photo_preset"
    
    static func uploadToCloudinary(image: UIImage, completion: @escaping (String?) -> Void) {
        
        // ★ 1. アップロード前に画像の長辺を 800px にリサイズする
        // (元の画像が800pxより小さければそのまま、大きければ縮小します)
        let resizedImage = resizeImage(image, maxDimension: 800.0) ?? image
        
        // ★ 2. リサイズされた画像を 0.6 の画質で Data 型に変換する
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.4) else {
            print("画像データの変換に失敗しました")
            completion(nil)
            return
        }
        
        // ★ デバッグ用：圧縮後の実際のファイルサイズをコンソールに表示
        let fileSizeStr = ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file)
        print("Cloudinaryへアップロード開始 (軽量化後のサイズ: \(fileSizeStr))")
        
        cloudinary.createUploader().upload(data: imageData, uploadPreset: uploadPreset, progress: { progress in
            print("進捗: \(progress.fractionCompleted)")
        }) { result, error in
            if let error = error {
                print("Cloudinaryアップロードエラー: \(error)")
                completion(nil)
                return
            }
            if let urlString = result?.secureUrl {
                print("アップロード成功, URL: \(urlString)")
                completion(urlString)
            } else {
                completion(nil)
            }
        }
    }
    
    // ★ 3. 画像の縦横比を維持したまま縮小するためのヘルパー関数
    private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        // 元の画像が指定サイズより小さければ何もしない
        if max(image.size.width, image.size.height) <= maxDimension {
            return image
        }
        
        let aspectRatio = image.size.width / image.size.height
        var newSize: CGSize
        
        if image.size.width > image.size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // デバイスの Retina 倍率に引っ張られないよう1.0に固定
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
//    //TODO: このコードをけして、Firebaseに保存されているURLを直接手動で変更する
//    static func optimizeUrl(_ originalUrlString: String) -> String {
//            // URLの中に "/upload/" が含まれているか確認
//            let target = "/upload/"
//            if originalUrlString.contains(target) {
//                // "/upload/" を "/upload/w_800,q_auto,f_auto/" に置き換える
//                // w_800: 長辺または横幅を800pxに
//                // q_auto: 画質を自動で最適な設定に（0.6と同等かそれ以上に賢く圧縮）
//                // f_auto: 端末に合わせて最適な画像フォーマット（WebPなど）に自動変換
//                let optimizedTarget = "/upload/w_800,q_auto,f_auto/"
//                return originalUrlString.replacingOccurrences(of: target, with: optimizedTarget)
//            }
//            return originalUrlString // 万が一対象外のURLならそのまま返す
//        }
}
