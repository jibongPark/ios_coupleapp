//
//  ImageLib.swift
//  Core
//
//  Created by 박지봉 on 3/19/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import UIKit

public struct ImageLib {
    public static func saveJPEGToDocument(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.5) else { return nil }
        
            let filename = UUID().uuidString + ".jpeg"
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent(filename)
            
            do {
                try data.write(to: fileURL)
                return filename
            } catch {
                print("Error saving image: \(error)")
                return nil
            }
    }
    
    public static func saveJPEGToDocument(_ image: UIImage, imageName: String) -> String {
        guard let data = image.jpegData(compressionQuality: 0.5) else { return "" }
        
            let filename = imageName + ".jpeg"
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent(filename)
            
            do {
                try data.write(to: fileURL)
                return filename
            } catch {
                print("Error saving image: \(error)")
                return ""
            }
    }
    
    public static func saveJPEGToGroup(_ image: UIImage, imageName: String, groupName: String) -> String {
        
        guard let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName) else {
            print("공유 컨테이너 URL을 찾을 수 없습니다.")
            return ""
        }
        
        guard let data = image.jpegData(compressionQuality: 1) else { return "" }
        
        let filename = imageName + ".jpeg"
        let fileURL = sharedURL.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return filename
        } catch {
            print("Error saving image: \(error)")
            return ""
        }
    }
    
    public static func removeImageFromGroup(withFilename filename: String, groupName: String) {
        guard let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName) else {
            print("공유 컨테이너 URL을 찾을 수 없습니다.")
            return
        }
        
        let fileURL = sharedURL.appendingPathComponent(filename)
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            print("removeFile Fail")
        }
    }
    
    public static func loadImageFromGroup(withFileName filename: String, groupName: String) -> UIImage? {
        
        guard let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName) else {
            print("공유 컨테이너 URL을 찾을 수 없습니다.")
            return nil
        }
        
        let fileURL = sharedURL.appendingPathComponent(filename)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    public static func loadImageFromDocument(withFilename filename: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        return UIImage(contentsOfFile: fileURL.path)
    }
    

    
    public static func removeAllImagesFromDocument(witfFIlenames filenames: [String]) async {
        for filename in filenames {
            removeImageFromDocument(withFilename: filename)
        }
    }
    
    public static func removeImageFromDocument(withFilename filename: String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("remove image successfully")
        } catch {
            print("Error removing image: \(error)")
        }
    }
}
