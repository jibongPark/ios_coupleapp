//
//  CalendarDTO.swift
//  CalendarData
//
//  Created by 박지봉 on 3/25/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import Domain

import RealmSwift

final class TodoDTO: Object {
    
    @Persisted(primaryKey: true) public var id: Int
    @Persisted public var title: String
    @Persisted public var memo: String
    @Persisted public var endDate: Date
    @Persisted public var isDone: Bool
    
    public override init() {
        
    }
    
    public init(id: Int = UUID().hashValue, title: String, memo: String, endDate: Date, isDone: Bool) {
        super.init()
        self.id = id
        self.title = title
        self.memo = memo
        self.endDate = endDate
        self.isDone = isDone
    }
    
    public init(from vo: TodoVO) {
        super.init()
        self.id = vo.id
        self.title = vo.title
        self.memo = vo.memo
        self.endDate = vo.endDate
        self.isDone = vo.isDone
    }
    
    public func toVO() -> TodoVO {
        return TodoVO(id: id, title: title, memo: memo, endDate: endDate, isDone: isDone)
    }
}

final class ScheduleDTO: Object {
    
    @Persisted(primaryKey: true) public var id: Int
    @Persisted public var title: String
    @Persisted public var startDate: Date
    @Persisted public var endDate: Date
    @Persisted public var memo: String
    
    public override init() {
    }
    
    public init(id: Int = UUID().hashValue, title: String, startDate: Date, endDate: Date, memo: String) {
        super.init()
        self.id = id
        self.title = title
        self.memo = memo
        self.startDate = startDate
        self.endDate = endDate
    }
    
    public init(from vo:ScheduleVO) {
        super.init()
        self.id = vo.id
        self.title = vo.title
        self.memo = vo.memo
        self.startDate = vo.startDate
        self.endDate = vo.endDate
    }
    
    public func toVO() -> ScheduleVO {
        return ScheduleVO(id: id, title: title, startDate: startDate, endDate: endDate, memo: memo)
    }
}

final class DiaryDTO: Object {
    
    @Persisted(primaryKey: true) public var date: String
    @Persisted public var content: String
    
    public override init() {
    }
    
    public init(date: Date, content: String) {
        super.init()
        self.date = date.calendarKeyString
        self.content = content
    }
    
    public init(from vo: DiaryVO) {
        super.init()
        self.date = vo.date.calendarKeyString
        self.content = vo.content
    }
    
    public func toVO() -> DiaryVO {
        return DiaryVO(date: Date.calendarKeyFormatter.date(from: date)!, content: content)
    }
    
}
