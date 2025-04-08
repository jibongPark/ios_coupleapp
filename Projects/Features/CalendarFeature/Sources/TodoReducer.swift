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
import SwiftUICore

@Reducer
struct TodoReducer {
    
    @Dependency(\.calendarRepository) var calendarRepository
    
    init() {
        
    }
    
    @ObservableState
    struct State: Equatable {
        init(id: Int = UUID().hashValue, date: Date, title: String = "", content: String = "", isDone: Bool = false, color: Color = .blue) {
            self.id = id
            self.date = date
            self.title = title
            self.content = content
            self.isDone = isDone
            self.color = color
        }
        
        var id: Int
        var date: Date
        var title: String
        var content: String
        var isDone: Bool
        var color: Color
    }
    
    public enum Action: BindableAction, Equatable {
        case delegate(Delegate)
        case binding(BindingAction<State>)
        case saveButtonTapped
        case saveTodo(TodoVO)
        
        public enum Delegate: Equatable {
            case addTodo(TodoVO)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
                
            case .delegate:
                return .none
                
            case .saveButtonTapped:
                let todoVO = TodoVO(id: state.id, title: state.title, memo: state.content, endDate: state.date, isDone: state.isDone, color: state.color)
                return .run { [todoVO = todoVO] send in
                    await send(.saveTodo(todoVO))
                    await send(.delegate(.addTodo(todoVO)))
                    await self.dismiss()
                }
                
            case .saveTodo(let todoVO):
                calendarRepository.updateTodo(todoVO)
                return .none
                
            case .binding(_):
                return .none
            }
        }
    }
}
