//
//  ImageUpload.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/19.
//

import Foundation
import UIKit
import Cloudinary

class ImageService{
    static let cloudinary = CLDCloudinary(configuration: CLDConfiguration(cloudName: "dytxyrksy", secure: true))
    
    static let uploadPreset = "imaco_photo_preset"
    
    static func uploadToCloudinary(image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8)else{
            print("画像データの変換に失敗しました")
            completion(nil)
            return
        }
        
        print("Cloudinaryhへアップロード開始")
        cloudinary.createUploader().upload(data: imageData, uploadPreset: uploadPreset, progress: { progress in
            print("進捗: \(progress.fractionCompleted)")
        }){ result, error in
            if let error = error {
                print("Cloudinaryアップロードエラー: \(error)")
                completion(nil)
                return
            }
            if let urlString = result?.secureUrl {
                print("アップロード成功,URL: \(urlString)")
                completion(urlString)
            }else{
                completion(nil)
            }
        }
    }
}
