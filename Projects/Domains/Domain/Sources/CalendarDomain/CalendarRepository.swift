//
//  CalendarRepository.swift
//  Domain
//
//  Created by 박지봉 on 3/25/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import ComposableArchitecture
import Foundation

public protocol CalendarRepository {
    
    func fetch(for date: Date) -> Effect<CalendarDatas>
    
    func updateTodo(_ todo: TodoVO)
    func updateDiary(_ diary: DiaryVO)
    func updateSchedule(_ schedule: ScheduleVO)
    
    func deleteTodo(_ id: String)
    func deleteDiary(_ id: String)
    func deleteSchedule(_ id: String)
    
    func syncServer()
    
}
