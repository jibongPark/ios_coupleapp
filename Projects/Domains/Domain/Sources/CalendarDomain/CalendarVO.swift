//
//  CalendarVO.swift
//  Domain
//
//  Created by 박지봉 on 3/25/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation

enum CalendarDataType: Equatable {
    case todo
    case diary
    case schedule
}

public struct TodoVO: Identifiable, Equatable, Hashable {
    
    public init(id: Int = UUID().hashValue, title: String = "", memo: String = "", endDate: Date = Date(), isDone: Bool = false) {
        self.id = id
        self.title = title
        self.memo = memo
        self.endDate = endDate
        self.isDone = isDone
    }
    
    public let id: Int
    public let title: String
    public let memo: String
    public let endDate: Date
    public var isDone: Bool
}

public struct ScheduleVO: Identifiable, Equatable {
    
    public init(id: Int = UUID().hashValue, title: String, startDate: Date, endDate: Date, memo: String) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.memo = memo
    }
    
    public var id: Int
    public var title: String
    public var startDate: Date
    public var endDate: Date
    public var memo: String
}

public extension ScheduleVO {
    func dateKeys() -> [String] {
        let calendar = Calendar.current
            
        var keys: [String] = []
        var currentDate = calendar.startOfDay(for: self.startDate)
        let endDate = calendar.startOfDay(for: self.endDate)
        
        while currentDate <= endDate {
            let key = currentDate.calendarKeyString
            keys.append(key)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        return keys
    }
}

public struct DiaryVO: Identifiable, Equatable {
    
    public init(date: Date = Date(), content: String = "") {
        self.date = date
        self.content = content
    }
    
    public var id: Date { date }
    public let date: Date
    public let content: String
    
}

public extension Date {
    static let calendarKeyFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "YYYYMMdd"
      return formatter
    }()
    
    var calendarKeyString: String {
      return Date.calendarKeyFormatter.string(from: self)
    }
}
