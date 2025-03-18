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

@Reducer
public struct AddTripReducer {
    
    @Dependency(\.mapRepository) var mapRepository
    
    @ObservableState
    public struct State: Equatable {
        
        @Presents var imagePicker: ImagePickerReducer.State?
        
        let sigunguCode: Int
        var images: [Data] = []
        var startDate: Date = Date.now
        var endDate: Date = Date.now
        var memo: String = ""
        var tripVO: TripVO? = nil
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
        
        case imagePicker(PresentationAction<ImagePickerReducer.Action>)
    }
    
    @Dependency(\.dismiss) var dismiss
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            case .delegate:
                return .none
                
            case .cancelButtonTapped:
                return .run { _ in await self.dismiss() }
                
            case .saveButtonTapped:
                state.tripVO = TripVO(sigunguCode: state.sigunguCode, images: state.images, startDate: state.startDate, endDate: state.endDate, memo: state.memo)
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
                
            case .imagePicker(.presented(.delegate(.didFinishPicking(let images)))):
                state.images = images
                return .none
                
            case .imagePicker:
                return .none
            }
        }
        .ifLet(\.$imagePicker, action: \.imagePicker) {
            ImagePickerReducer()
        }
    }
}
