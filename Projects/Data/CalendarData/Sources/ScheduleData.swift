//
//  ScheduleDTO.swift
//  CalendarData
//
//  Created by 박지봉 on 2/7/25.
//  Copyright © 2025 SampleCompany. All rights reserved.
//

import Foundation

struct ScheduleDTO: Codable {
    let id: Int
    let title: String
    let startDate: Date
    let endDate: Date
    let memo: String?
}

protocol ScheduleRepository {
    func fetchSelectedMonth(month: Date) -> [ScheduleDTO]
}

class ScheduleRepositoryImpl: ScheduleRepository {
    func fetchSelectedMonth(month: Date) -> [ScheduleDTO] {
        
        
        
        return []
    }
}
