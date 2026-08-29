//
//  ImageUpload.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/19.
//

import Foundation
import UIKit
import Cloudinary
import FirebaseFirestore

class ImageService {
    static let cloudinary = CLDCloudinary(configuration: CLDConfiguration(cloudName: "dytxyrksy", secure: true))
    
    static let uploadPreset = "imaco_photo_preset"
    
    //画像をCloudinaryにアップロードする関数
    static func uploadToCloudinary(image: UIImage, completion: @escaping ((url: String, publicId: String)?) -> Void) {
        let resizedImage = resizeImage(image, maxDimension: 800.0) ?? image
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.4) else {
            print("画像データの変換に失敗しました")
            completion(nil)
            return
        }
        
        cloudinary.createUploader().upload(data: imageData, uploadPreset: uploadPreset, progress: { progress in
        }) { result, error in
            if let error = error {
                print("Cloudinaryアップロードエラー: \(error)")
                completion(nil)
                return
            }
            if let urlString = result?.secureUrl, let publicId = result?.publicId {
                completion((url: urlString, publicId: publicId))
            } else {
                completion(nil)
            }
        }
    }
    
    //画質を落とすために画像をリサイズ
    private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
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
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

