//
//  CaeldnarFeature.swift
//  CalendarFeature
//
//  Created by 박지봉 on 2/10/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import ComposableArchitecture

@Reducer
public struct CalendarReducer {
    
    public init() {
        
    }
    
    public enum Route: Equatable {
        case none
        case diary
        case schedule
        case todo
    }
    
    @Reducer(state: .equatable)
    public enum Path {
        case diaryView(DiaryReducer)
        case testView
    }
    
    @ObservableState
    public struct State: Equatable {
        
        public init(selectedMonth: Date?) {
            self.selectedMonth = selectedMonth ?? Date()
        }
        
        
        public var selectedMonth: Date
        public var selectedDate: Date = Date()
        var route: Route = .none
        var path = StackState<Path.State>()
        
        @Presents public var destination: Destination.State?
    }
    
    public enum Action {
        case destination(PresentationAction<Destination.Action>)
        case searchAllData
        case navigateTo(Route)
        case selectedMonthChange(Date)
        case selectedDateChange(Date)
        case path(StackActionOf<Path>)
    }
    
    public static let reducer = Self()
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .searchAllData:
                return .none
                
            case let .navigateTo(navigateType):
                state.destination = .diaryView(
                    DiaryReducer.State(
                        date:state.selectedDate
                    )
                )
                return .none
            case let .selectedMonthChange(month):
                state.selectedMonth = month
                return .none
            case let .selectedDateChange(date):
                state.selectedDate = date
                return .none
            case let .path(action):
                
                state.path.append(.diaryView(DiaryReducer.State(date: Date())))
                
                return .none
                
                //             case let .destination(.presented(.diaryView(<#T##DiaryReducer.Action#>)(<#T##DiaryReducer.Action#>)(.delegate(.)))):
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension CalendarReducer {
    
    @Reducer
    public enum Destination {
        case diaryView(DiaryReducer)
    }
}

extension CalendarReducer.Destination.State: Equatable {}


