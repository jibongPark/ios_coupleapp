//
//  DiaryReducer.swift
//  DiaryFeature
//
//  Created by 박지봉 on 2/10/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct DiaryReducer {
    
    @Dependency(\.calendarRepository) var calendarRepository
    
    public init() {
        
    }
    
    @ObservableState
    public struct State: Equatable {
        public init(date: Date, content: String = "") {
            self.date = date
            self.content = content
        }
        
        var date: Date
        var content: String
    }
    
    public enum Action: BindableAction, Equatable {
        case delegate(Delegate)
        case binding(BindingAction<State>)
        case confirmButtonTapped
        case saveDiary(DiaryVO)
        
        public enum Delegate: Equatable {
            case addDiary(DiaryVO)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
                
            case .delegate:
                return .none
                
            case .confirmButtonTapped:
                let diaryVO = DiaryVO(date: state.date, content: state.content)
                return .run { [diaryVO = diaryVO] send in
                    await send(.saveDiary(diaryVO))
                    await send(.delegate(.addDiary(diaryVO)))
                    await self.dismiss()
                }
                
            case .saveDiary(let diaryVO):
                calendarRepository.updateDiary(diaryVO)
                return .none
                
            case .binding(_):
                return .none
            }
        }
    }
}
