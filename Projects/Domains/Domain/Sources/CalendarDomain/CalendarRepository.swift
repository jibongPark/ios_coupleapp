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
    
    func fetchTodo(ofMonth: Date) -> Effect<[String: [TodoVO]]>
    func fetchDiary(ofMonth: Date) -> Effect<[String: DiaryVO]>
    func fetchSchedule(ofMonth: Date) -> Effect<[String: [ScheduleVO]]>
    
    func updateTodo(_ todo: TodoVO)
    func updateDiary(_ diary: DiaryVO)
    func updateSchedule(_ schedule: ScheduleVO)
    
}
