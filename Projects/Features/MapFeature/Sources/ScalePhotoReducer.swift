//
//  ScalePhotoReducer.swift
//  MapFeature
//
//  Created by 박지봉 on 3/18/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct ScalePhotoReducer {
    
    @ObservableState
    public struct State: Equatable {
        var scale: Float
        var position: CGPoint
        
        let polygonShape: PolygonData
        let image: Data
    }
    
    public enum Action {
        
        case didChangeScale(Float)
        case didChangePosition(CGPoint)
        
        case doneButtonTapped
        case delegate(Delegate)
        public enum Delegate: Equatable {
            case scaleDone(Float, CGPoint)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            case .didChangeScale(let scale):
                state.scale = scale
                return .none
                
            case .didChangePosition(let position):
                state.position = position
                return .none
                
            case .doneButtonTapped:
                return .run { [scale = state.scale, position = state.position] send in
                    await send(.delegate(.scaleDone(scale, position)))
                    await self.dismiss()
                }
                
            default:
                return .none
            }
        }
    }
}
