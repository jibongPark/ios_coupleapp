//
//  AddTripReducer.swift
//  MapFeature
//
//  Created by 박지봉 on 3/13/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import ComposableArchitecture
import SwiftUICore
import Domain
import Core
import UIKit

@Reducer
public struct AddTripReducer {
    
    @Dependency(\.mapRepository) var mapRepository
    
    @ObservableState
    public struct State: Equatable {
        
        @Presents var imagePicker: ImagePickerReducer.State?
        @Presents var scalePhoto: ScalePhotoReducer.State?
        
        let polygon: PolygonData
        var images: [String] = []
        var newImages: [String] = []
        var startDate: Date = Date.now
        var endDate: Date = Date.now
        var memo: String = ""
        var scale: Float = 1
        var center: CGPoint = .zero
        var tripVO: TripVO? = nil
        
        var isEditing: Bool = false
        
        public init(polygon: PolygonData, tripVO: TripVO? = nil) {
            self.polygon = polygon
        
            self.images = tripVO?.images ?? []
            self.startDate = tripVO?.startDate ?? Date.now
            self.endDate = tripVO?.endDate ?? Date.now
            self.memo = tripVO?.memo ?? ""
            self.scale = tripVO?.scale ?? 1
            self.center = tripVO?.center ?? .zero
        }
    }
    
    public enum Action {
        case delegate(Delegate)
        case cancelButtonTapped
        case saveButtonTapped
        case setMemo(String)
        case setStartDate(Date)
        case setEndDate(Date)
        case addImageButtonTapped
        case saveTripData(TripVO)
        public enum Delegate: Equatable {
            case saveTrip(TripVO)
        }
        
        case deleteImage(Int)
        
        case imagePicker(PresentationAction<ImagePickerReducer.Action>)
        case imageLongPressed
        
        case scaleImageButtonTapped
        case scaleImage(PresentationAction<ScalePhotoReducer.Action>)
    }
    
    @Dependency(\.dismiss) var dismiss
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            case .delegate:
                return .none
                
            case .cancelButtonTapped:
                return .run { [images = state.newImages] send in
                    await ImageLib.removeAllImagesFromDocument(witfFIlenames: images)
                    await self.dismiss() }
                
            case .saveButtonTapped:
                state.tripVO = TripVO(sigunguCode: state.polygon.sigunguCode, images: state.images, startDate: state.startDate, endDate: state.endDate, memo: state.memo, scale: state.scale, center: state.center)
                return .run { [tripVO = state.tripVO!] send in
                    await send(.saveTripData(tripVO))
                    await send(.delegate(.saveTrip(tripVO)))
                    await self.dismiss()
                }
                
            case .setMemo(let memo):
                state.memo = memo
                return .none
                
            case .setStartDate(let date):
                state.startDate = date
                return .none
                
            case .setEndDate(let date):
                state.endDate = date
                return .none
                
            case .addImageButtonTapped:
                state.imagePicker = ImagePickerReducer.State()
                return .none
                
            case .saveTripData(let tripVO):
                mapRepository.updateTrip(tripVO)
                return .none
                
            case .deleteImage(let index):
                let path = state.images[index]
                ImageLib.removeImageFromDocument(withFilename: path)
                state.images.remove(at: index)
                return .none
                
            case .imagePicker(.presented(.delegate(.didFinishPicking(let images)))):
                var newPaths = [String]()
                for image in images {
                    if let newImagePath = ImageLib.saveJPEGToDocument(image) {
                        newPaths.append(newImagePath)
                    }
                }
                state.newImages = state.newImages + newPaths
                state.images = state.images + newPaths
                return .none
                
            case .imagePicker:
                return .none
                
            case .imageLongPressed:
                state.isEditing.toggle()
                return .none
                
            case .scaleImageButtonTapped:
                state.scalePhoto = ScalePhotoReducer.State(scale: state.scale, position: state.center, polygonShape: state.polygon, imagePath: state.images[0])
                return .none
                
            case .scaleImage(.presented(.delegate(.scaleDone(let scale, let position)))):
                state.scale = scale
                state.center = position
                return .none
                
            case .scaleImage:
                return .none
                
            }
        }
        .ifLet(\.$imagePicker, action: \.imagePicker) {
            ImagePickerReducer()
        }
        .ifLet(\.$scalePhoto, action: \.scaleImage) {
            ScalePhotoReducer()
        }
    }
}
