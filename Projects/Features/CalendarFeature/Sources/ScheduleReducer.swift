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
public struct ScheduleReducer {
    
    @Dependency(\.calendarRepository) var calendarRepository
    
    public init() {
        
    }
    
    @ObservableState
    public struct State: Equatable {
        public init(id: Int = UUID().hashValue, title: String = "", content: String = "", startDate: Date = Date(), endDate: Date = Date()) {
            self.id = id
            self.title = title
            self.content = content
            self.startDate = startDate
            self.endDate = endDate
        }
        
        var id: Int
        var title: String
        var startDate: Date
        var endDate: Date
        var content: String
    }
    
    public enum Action: BindableAction, Equatable {
        case delegate(Delegate)
        case binding(BindingAction<State>)
        case saveButtonTapped
        case saveSchedule(ScheduleVO)
        
        public enum Delegate: Equatable {
            case addSchedule(ScheduleVO)
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
                let scheduleVO = ScheduleVO(id: state.id, title: state.title, startDate: state.startDate, endDate: state.endDate, memo: state.content)
                
                return .run { [scheduleVO = scheduleVO] send in
                    await send(.saveSchedule(scheduleVO))
                    await send(.delegate(.addSchedule(scheduleVO)))
                    await self.dismiss()
                }
                
            case .saveSchedule(let schedule):
                calendarRepository.updateSchedule(schedule)
                return .none
                
            case .binding(_):
                return .none
            }
        }
    }
}
