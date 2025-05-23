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
import SwiftUICore

struct CalendarDTO: Decodable {
    var todos: [TodoDTO]
    var schedules: [ScheduleDTO]
    var diaries: [DiaryDTO]
}

public final class TodoDTO: Object, Decodable {
    
    @Persisted(primaryKey: true) public var id: String
    @Persisted public var author: String
    @Persisted public var title: String
    @Persisted public var memo: String
    @Persisted public var endDate: Date
    @Persisted public var isDone: Bool
    @Persisted public var color: Int
    @Persisted public var shared: List<String>
    @Persisted public var createdAt: Date
    @Persisted public var updatedAt: Date
    
    public override init() {
        
    }
    
    public init(id: String = "", title: String, memo: String, endDate: Date, isDone: Bool) {
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
        self.color = vo.color.toInt()
    }
    
    public func toVO() -> TodoVO {
        return TodoVO(id: id, title: title, memo: memo, endDate: endDate, isDone: isDone, color: Color(int:color))
    }
}

public final class ScheduleDTO: Object, Decodable {
    
    @Persisted(primaryKey: true) public var id: String
    @Persisted public var author: String
    @Persisted public var title: String
    @Persisted public var startDate: Date
    @Persisted public var endDate: Date
    @Persisted public var memo: String
    @Persisted public var color: Int
    @Persisted public var shared: List<String>
    @Persisted public var createdAt: Date
    @Persisted public var updatedAt: Date
    
    public override init() {
    }
    
    public init(id: String = "", title: String, startDate: Date, endDate: Date, memo: String) {
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
        self.color = vo.color.toInt()
    }
    
    public func toVO() -> ScheduleVO {
        return ScheduleVO(id: id, title: title, startDate: startDate, endDate: endDate, memo: memo, color: Color(int:color))
    }
}

public final class DiaryDTO: Object, Decodable {
    
    @Persisted(primaryKey: true) public var id: String
    @Persisted public var author: String
    @Persisted public var date: Date
    @Persisted public var content: String
    @Persisted public var shared: List<String>
    @Persisted public var createdAt: Date
    @Persisted public var updatedAt: Date
    
    public override init() {
    }
    
    public init(date: Date, content: String) {
        super.init()
        self.date = date
        self.content = content
    }
    
    public init(from vo: DiaryVO) {
        super.init()
        self.date = vo.date
        self.content = vo.content
    }
    
    public func toVO() -> DiaryVO {
        return DiaryVO(date: date, content: content)
    }
}

public final class CalendarOp: Object {
    @Persisted(primaryKey: true) public var id: String
    @Persisted public var type: String
    @Persisted public var method: String
    
    public override init() {
        
    }
    
    public init(id: String, type: String, method: String) {
        super.init()
        self.id = id
        self.type = type
        self.method = method
    }
}
