//
//  CaeldnarFeature.swift
//  CalendarFeature
//
//  Created by 박지봉 on 2/10/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import ComposableArchitecture
import Domain
import Core

@Reducer
struct CalendarReducer {
    
    @Dependency(\.calendarRepository) var calendarRepository
    
    init() {
        
    }
    
    enum Route: Equatable {
        case none
        case diary
        case schedule(ScheduleVO?)
        case todo(TodoVO?)
    }
    
    enum Expand: Equatable {
        case half
        case full
        case none
    }
    
    @ObservableState
    struct State: Equatable {
        
        init(selectedMonth: Date?) {
            self.selectedMonth = selectedMonth ?? Date()
        }
        
        var todoData: [String: [TodoVO]] = [:]
        var diaryData: [String: DiaryVO] = [:]
        var scheduleData: [String: [ScheduleVO]] = [:]
        
        
        var selectedMonth: Date
        var selectedDate: Date = Date()
        var route: Route = .none
        
        @Presents var destination: Destination.State?
    }
    
    enum Action {
        case destination(PresentationAction<Destination.Action>)
        case searchAllData
        case didLoadData(CalendarDatas)
        case navigateTo(Route)
        case selectedMonthChange(Date)
        case selectedDateChange(Date)
        
        case todoDidToggle(TodoVO)
        
        case didTapMonth
        case didTapGotoToday
        case sync
    }
    
    static let reducer = Self()
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .searchAllData:
                
                let month = state.selectedMonth
                
                return .merge(
                    calendarRepository.fetch(for: month)
                        .map { @Sendable datas in
                                .didLoadData(datas)
                        }
                )
            case .didLoadData(let datas):
                state.diaryData = datas.diaries
                state.todoData = datas.todos
                state.scheduleData = datas.schedules
                return .none
                
            case let .navigateTo(navigateType):
                
                switch navigateType {
                case .diary:
                    
                    let content = state.diaryData[state.selectedDate.calendarKeyString]?.content ?? ""
                    
                    state.destination = .diaryView(
                        DiaryReducer.State(
                            date:state.selectedDate,
                            content: content
                        )
                    )
                    
                    return .none
                    
                case let .todo(todoVO):
                    
                    let id = todoVO?.id ?? ""
                    let date = todoVO?.endDate ?? state.selectedDate
                    let title = todoVO?.title ?? ""
                    let content = todoVO?.memo ?? ""
                    let isDone = todoVO?.isDone ?? false
                    let color = todoVO?.color ?? .blue
                    
                    state.destination = .todoView(
                        TodoReducer.State(
                            id: id,
                            date:date,
                            title: title,
                            content: content,
                            isDone: isDone,
                            color: color
                        )
                    )
                    return .none
                    
                case let .schedule(scheduleVO):
                    
                    let id = scheduleVO?.id ?? ""
                    let title = scheduleVO?.title ?? ""
                    let startDate = scheduleVO?.startDate ?? state.selectedDate
                    let endDate = scheduleVO?.endDate ?? state.selectedDate
                    let memo = scheduleVO?.memo ?? ""
                    let color = scheduleVO?.color ?? .blue
                    
                    
                    state.destination = .scheduleView(
                        ScheduleReducer.State(
                            id: id,
                            title: title,
                            content: memo,
                            startDate: startDate,
                            endDate: endDate,
                            color: color
                        )
                    )
                    
                case .none:
                    break
                }
                
                return .none
            case let .selectedMonthChange(month):
                state.selectedMonth = month
                
                if(month.month != state.selectedDate.month) {
                    state.selectedDate = month.getDate(for: 0)
                }
                return .run { send in
                    await send(.searchAllData)
                }
                
            case let .selectedDateChange(date):
                state.selectedDate = date
                
                return .none
                
            case let .todoDidToggle(todo):
                calendarRepository.updateTodo(todo)
                return .none
                
            case .didTapMonth:
                state.destination = .datePickerView(DatePickerReducer.State(date: state.selectedDate))
                return .none
                
            case .didTapGotoToday:
                return .run { send in
                    await send(.selectedMonthChange(Date()))
                    await send(.selectedDateChange(Date()))
                }
                
            case .sync:
                calendarRepository.syncServer()
                return .none
                
            case let .destination(.presented(.diaryView(.delegate(.addDiary(diary))))):
                state.diaryData[diary.date.calendarKeyString] = diary
                return .none
                
            case let .destination(.presented(.scheduleView(.delegate(.addSchedule(schedule))))):
                
                state.scheduleData[schedule.startDate.calendarKeyString, default: []] += [schedule]
                return .none
                
            case let .destination(.presented(.todoView(.delegate(.addTodo(todo))))):
                var array = state.todoData[todo.endDate.calendarKeyString, default: []]
                
                if let index = array.firstIndex(where: { $0.id == todo.id }) {
                    array[index] = todo
                } else {
                    array.append(todo)
                }
                return .none
                
            case .destination(.presented(.datePickerView(.delegate(.didFinishPicking(let date))))):
                return .run { send in
                    await send(.selectedMonthChange(date))
                    await send(.selectedDateChange(date))
                }
                
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
        case todoView(TodoReducer)
        case scheduleView(ScheduleReducer)
        case datePickerView(DatePickerReducer)
    }
}

extension CalendarReducer.Destination.State: Equatable {}


