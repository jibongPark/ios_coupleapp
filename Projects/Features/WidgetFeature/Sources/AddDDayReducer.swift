//
//  AddDDayReducer.swift
//  WidgetFeature
//
//  Created by 박지봉 on 4/11/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import ComposableArchitecture
import Core
import UIKit
import SwiftUICore
import Domain
import WidgetData

@Reducer
struct AddDDayReducer {
    
    @Dependency(\.widgetRepository) var widgetRepository
    
    init() { }
    
    @ObservableState
    struct State: Equatable {
        init(id: Int = UUID().hashValue, title: String = "", startDate: Date = Date(), imagePath: String = "", image: UIImage? = nil) {
            self.id = id
            self.title = title
            self.startDate = startDate
            self.imagePath = imagePath
            self.image = image
        }
        
        init(vo: WidgetVO) {
            self.id = vo.id
            self.title = vo.title
            self.startDate = vo.startDate
            self.imagePath = vo.imagePath
        }
        
        var id: Int
        var title: String
        var startDate: Date
        var imagePath: String
        
        var image: UIImage?
        
        @Presents var destination: Destination.State?
        
    }
    
    enum Action: BindableAction {
        
        case cancelButtonTapped
        case saveButtonTapped
        
        case addPhotoButtonTapped
        case dateChangeButtonTapped
        
        case delegate(Delegate)
        
        case destination(PresentationAction<Destination.Action>)
        case binding(BindingAction<State>)
        public enum Delegate: Equatable {
            case addDDayData(WidgetVO)
        }
    }
    
    static let reducer = Self()
    
    @Dependency(\.dismiss) var dismiss
    
    public var body: some Reducer<State, Action> {
        
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            
            case .cancelButtonTapped:
                return .run {send in 
                    await dismiss()
                }
                
            case .saveButtonTapped:
                
                if let image = state.image {
                    state.imagePath = ImageLib.saveJPEGToGroup(image, imageName: String(state.id), groupName: "group.com.bongbong.coupleapp")
                }
                
                let _ = print("imageSize : \(state.image?.size ?? CGSize.zero)")
                
                let widgetVO = WidgetVO(id: state.id, title: state.title, memo: "", startDate: state.startDate, imagePath: state.imagePath, alignment: .center)
                return .run { [widgetVO] send in
                    await send(.delegate(.addDDayData(widgetVO)))
                    await widgetRepository.updateWidget(widgetVO)
                    await dismiss()
                }

            case .addPhotoButtonTapped:
                state.destination = .photoPicker(ImagePickerReducer.State(
                    imageLimits: 1
                ))
                return .none
                
            case .dateChangeButtonTapped:
                state.destination = .datePicker(DatePickerReducer.State())
                return .none
                
            case .delegate:
                return .none
                
            case .destination(.presented(.photoPicker(.delegate(.didFinishPicking(let images))))):
                let resizeImage = images.first!.resize(to: CGSize(width: 200, height: 400))
                
                state.image = resizeImage
                return .none
                
            case .destination(.presented(.datePicker(.delegate(.didFinishPicking(let date))))):
                state.startDate = date
                
                return .none
                
            case .destination:
                return .none
                
            case .binding:
                return .none
                
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension AddDDayReducer {
    @Reducer
    enum Destination {
        case photoPicker(ImagePickerReducer)
        case datePicker(DatePickerReducer)
    }
}

extension AddDDayReducer.Destination.State: Equatable {}
