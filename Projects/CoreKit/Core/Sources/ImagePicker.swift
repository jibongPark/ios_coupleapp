//
//  ImagePicker.swift
//  Core
//
//  Created by 박지봉 on 3/15/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import SwiftUI
import PhotosUI

public struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    // 선택 완료 시 호출할 클로저
    let onComplete: ([UIImage]) -> Void

    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0 // 0이면 무제한 선택, 1이면 단일 선택
        config.filter = .images  // 이미지만 선택 가능
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // 결과 배열의 순서가 선택한 순서와 동일하다고 가정
            var images: [UIImage] = []
            let group = DispatchGroup()
            
            for result in results {
                group.enter()
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                        if let image = object as? UIImage {
                            images.append(image)
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                self.parent.onComplete(images)
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
