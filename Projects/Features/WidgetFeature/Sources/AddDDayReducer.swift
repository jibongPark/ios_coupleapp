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
import WidgetKit

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
            self.isShowDate = vo.isShowDate
            self.isShowTitle = vo.isShowTitle
            self.dateAlignment = vo.dateAlignment.toTextAlignment()
            self.titleAlignment = vo.titleAlignment.toTextAlignment()
        }
        
        var id: Int
        var title: String
        var startDate: Date
        var imagePath: String
        var isShowDate: Bool = true
        var isShowTitle: Bool = true
        
        var dateAlignment: Alignment = .topLeading
        var titleAlignment: Alignment = .topLeading
        
        var image: UIImage?
        
        @Presents var destination: Destination.State?
        
    }
    
    enum Action: BindableAction {
        
        case cancelButtonTapped
        case saveButtonTapped
        
        case addPhotoButtonTapped
        case dateChangeButtonTapped
        
        case didTapDateAlignment(Alignment)
        case didTapTitleAlignment(Alignment)
        
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
                
                if state.image != nil && !state.imagePath.isEmpty {
                    ImageLib.removeImageFromGroup(withFilename: state.imagePath, groupName: "group.com.bongbong.coupleapp")
                }
                
                if let image = state.image {
                    state.imagePath = ImageLib.saveJPEGToGroup(image, imageName: (String(state.id) + String(UUID().hashValue)), groupName: "group.com.bongbong.coupleapp")
                }
                
                let widgetVO = WidgetVO(id: state.id,
                                        title: state.title,
                                        memo: "",
                                        startDate: state.startDate,
                                        imagePath: state.imagePath,
                                        isShowDate: state.isShowDate,
                                        dateAlignment: state.dateAlignment,
                                        isShowTitle: state.isShowTitle,
                                        titleAlignment: state.titleAlignment)
                
                return .run { [widgetVO] send in
                    await send(.delegate(.addDDayData(widgetVO)))
                    await widgetRepository.updateWidget(widgetVO)
                    WidgetCenter.shared.reloadTimelines(ofKind: "coupleapp_WidgetExtension")
                    await dismiss()
                }

            case .addPhotoButtonTapped:
                state.destination = .photoPicker(ImagePickerReducer.State(
                    imageLimits: 1
                ))
                return .none
                
            case .dateChangeButtonTapped:
                state.destination = .datePicker(DatePickerReducer.State(date: state.startDate))
                return .none
                
            case .didTapDateAlignment(let alignment):
                state.dateAlignment = alignment
                return .none
                
            case .didTapTitleAlignment(let alignment):
                state.titleAlignment = alignment
                return .none
                
            case .delegate:
                return .none
                
            case .destination(.presented(.photoPicker(.delegate(.didFinishPicking(let images))))):
                let resizeImage = images.first!.resize(toMaxByte: 900000)
                
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
