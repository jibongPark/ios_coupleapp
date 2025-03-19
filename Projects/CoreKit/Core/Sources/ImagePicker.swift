//
//  ImagePicker.swift
//  Core
//
//  Created by 박지봉 on 3/15/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import PhotosUI

@Reducer
public struct ImagePickerReducer {
    
    public init() {
    }
    
    @ObservableState
    public struct State: Equatable {
        public var images: [Data] = []
        
        public init(images: [Data] = []) {
            self.images = images
        }
    }
    
    public enum Action {
        case delegate(Delegate)
        case cancelButtonTapped
        case doneButtonTapped([UIImage])
        public enum Delegate: Equatable {
            case didFinishPicking(images: [UIImage])
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    public var body: some ReducerOf<Self> {
        
        Reduce { state, action in
            
            switch action {
                
            case .delegate:
                return .none
                
            case .cancelButtonTapped:
                return .run { _ in await self.dismiss() }
                
            case .doneButtonTapped(let images):
                var datas = [UIImage]()
                
                datas = images.map( { $0 })
                
                return .run { [datas] send in
                    await send(.delegate(.didFinishPicking(images: datas)))
                    await self.dismiss()
                }
            }
        }
    }
}

public struct ImagePickerView: UIViewControllerRepresentable {
    let store: StoreOf<ImagePickerReducer>
    
    public init(store: StoreOf<ImagePickerReducer>) {
        self.store = store
    }
    
    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0      // 0이면 무제한 선택, 원하는 개수로 제한 가능
        config.filter = .images         // 이미지만 선택
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        
        picker.presentationController?.delegate = context.coordinator
    
//        picker.modalPresentationStyle = .pageSheet
        
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }
    
    public class Coordinator: NSObject, PHPickerViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
        let store: StoreOf<ImagePickerReducer>
        
        init(store: StoreOf<ImagePickerReducer>) {
            self.store = store
        }
        
        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            var images: [UIImage] = []
            let group = DispatchGroup()
            
            for result in results {
                group.enter()
                

                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                        if let image = object as? UIImage {
                            
                            images.append(image)
                            
//                            if let imagePath = self.saveImage(image) {
//                                images.append(imagePath)
//                            }
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                if images.isEmpty {
                    self.store.send(.cancelButtonTapped)
                } else {
                    self.store.send(.doneButtonTapped(images))
                }
            }
        }
        
        private func saveImage(_ image: UIImage) -> String? {
            guard let data = image.pngData() else { return nil }
                let filename = UUID().uuidString + ".png"
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = documentsDirectory.appendingPathComponent(filename)
                
                do {
                    try data.write(to: fileURL)
                    return fileURL.path
                } catch {
                    print("Error saving image: \(error)")
                    return nil
                }
        }
    }
}
