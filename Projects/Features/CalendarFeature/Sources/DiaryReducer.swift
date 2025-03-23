//
//  DiaryReducer.swift
//  DiaryFeature
//
//  Created by 박지봉 on 2/10/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import ComposableArchitecture

@Reducer
public struct DiaryReducer {
    
    public init() {
        
    }
    
    public struct State: Equatable {
        public init(id: Int? = nil, date: Date, content: String? = nil) {
            self.id = id ?? -1
            self.date = date
            self.content = content ?? ""
        }
        
        var id: Int
        var date: Date
        @BindingState var content: String
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case confirm
        case changedText
        case searchDiary(Date)
    }
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
                
            case .confirm:
                return .none
                
            case .changedText:
                return .none
                
            case let .searchDiary(date):
                return .none
            case .binding(_):
                return .none
            }
        }
    }
}
