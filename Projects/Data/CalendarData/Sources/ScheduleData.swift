//
//  ScheduleDTO.swift
//  CalendarData
//
//  Created by 박지봉 on 2/7/25.
//  Copyright © 2025 SampleCompany. All rights reserved.
//

import Foundation
import SQLite

let tableName = "schedule"

struct ScheduleDTO: Codable {
    let id: Int
    let title: String
    let startDate: Date
    let endDate: Date
    let memo: String?
}

protocol ScheduleRepository {
    func fetchSelectedMonth(month: Date) -> [ScheduleDTO]
    func addSchedule(id: Int, title: String, startDate: Date, endDate: Date, memo: String?)
}

class ScheduleRepositoryImpl: ScheduleRepository {
    
    private let sqliteHelper = SQLiteHelper.shared
    
    func fetchSelectedMonth(month: Date) -> [ScheduleDTO] {
        return sqliteHelper.fetchObjects(tableName: tableName, type: ScheduleDTO.self)
    }
    
    func addSchedule(id: Int = -1, title: String, startDate: Date, endDate: Date, memo: String?) {
        
        let schedule = ScheduleDTO(id: id, title: title, startDate: startDate, endDate: endDate, memo: memo)
        sqliteHelper.insertOrUpdateObject(schedule, tableName: tableName, isUpdate: id != -1)
    }
}
