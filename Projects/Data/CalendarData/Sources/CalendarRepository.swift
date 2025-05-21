//
//  TestProject.swift
//  TestProject
//
//  Created by Junyoung on 1/8/25.
//

import SwiftUI
import Domain
import ComposableArchitecture
import RealmKit
import RealmSwift
import CommonData
import Moya

import Core

import Foundation

public typealias MoyaResultHandler = (Result<Response, MoyaError>) -> Void


public final class CalendarRepositoryImpl: CalendarRepository {
    
    @Dependency(\.authInterceptor) var authInterceptor
    @Dependency(\.realmKit) var realmKit
    @Dependency(\.authManager) var authManager
    
    private var fetchDateManager = FetchDateManager()
    
    public init() {}
    
    private lazy var session = Session(interceptor: authInterceptor)

    private lazy var provider = MoyaProvider<CalendarAPI>(session: session)
    
    public func fetch(for date: Date) -> Effect<CalendarDatas> {
        
        let (startDate, endDate) = gridStartAndEnd(for: date)
        
        let startDateString = ISO8601DateFormatter().string(from: startDate)
        let endDateString = ISO8601DateFormatter().string(from: endDate)
        
        let lastDate = fetchDateManager.lastFetch(for: date)
        
        let lastDateString = lastDate != nil ? ISO8601DateFormatter().string(from: lastDate!) : ""
        
        
        return Effect.run { [self] send async in
            
            if let didLogin: Bool = ConfigManager.shared.get("didLogin"),
               didLogin {
                let result: Result<Response, MoyaError> = await withCheckedContinuation { continuation in
                    provider.request(.calendar(startDate: startDateString, endDate: endDateString, lastFetch: lastDateString)) { moyaResult in
                        switch moyaResult {
                        case .success(let response):
                            continuation.resume(returning: .success(response))
                        case .failure(let moyaError):
                            continuation.resume(returning: .failure(moyaError))
                        }
                    }
                }
                
                switch result {
                case .success(let resp):
                    do {
                        let apiResp: APIResponse<CalendarDTO> =
                        try resp.mapAPIResponse(CalendarDTO.self)
                        
                        if let schedules = apiResp.data?.schedules {
                            realmKit.addDatas(schedules)
                        }
                        
                        if let todos = apiResp.data?.todos {
                            realmKit.addDatas(todos)
                        }
                        
                        if let diaries = apiResp.data?.diaries {
                            realmKit.addDatas(diaries)
                        }
                        
                        fetchDateManager.updateLastFetch(date)
                    } catch {
                        
                    }
                    break
                case .failure:
                    break
                }
            }
            
            async let todoDic: [String: [TodoVO]] = fetchTodo(withStartDate: startDate, endDate: endDate)
            async let diaryDic: [String : DiaryVO] = fetchDiary(withStartDate: startDate, endDate: endDate)
            async let scheduleDic: [String : [Domain.ScheduleVO]] = fetchSchedule(withStartDate: startDate, endDate: endDate)
            
            let (todoResult, diaryRsult, scheduleResult) = await (todoDic, diaryDic, scheduleDic)
            
            await send(CalendarDatas(todos: todoResult, diaries: diaryRsult, schedules: scheduleResult))
        }
    }
    
    public func fetchTodo(withStartDate start: Date, endDate end: Date) -> [String : [Domain.TodoVO]] {
        
        let todos = realmKit.fetchAllData(type: TodoDTO.self)
            .filter("endDate >= %@ AND endDate < %@", start, end)
        
        let todoDTOs = Dictionary(grouping: todos) { todo in
            todo.endDate.calendarKeyString
        }
        
        let todoVOs = todoDTOs.mapValues { dtoArray in
            dtoArray.map { $0.toVO() }
        }
        
        return todoVOs
    }
    
    public func fetchDiary(withStartDate start: Date, endDate end: Date) -> [String : Domain.DiaryVO] {
        
        let diaries = realmKit.fetchAllData(type: DiaryDTO.self)
            .filter("date >= %@ AND date < %@", start, end)
        
        let diariesDic = Dictionary(uniqueKeysWithValues:diaries.map { ($0.date.calendarKeyString, $0.toVO()) })
        
        return diariesDic
    }
    
    public func fetchSchedule(withStartDate start: Date, endDate end: Date) -> [String : [Domain.ScheduleVO]] {
        
        let schedules = realmKit.fetchAllData(type: ScheduleDTO.self)
            .filter("endDate >= %@ AND startDate < %@", start, end)
        
        let scheduleVOArray = schedules.map {
            $0.toVO()
        }
        
        var scheduleVOs = [String: [ScheduleVO]]()
        
        for schedule in scheduleVOArray {
            let keys = schedule.dateKeys()
            
            for key in keys {
                scheduleVOs[key, default: []].append(schedule)
            }
        }
        
        return scheduleVOs
    }
    
    public func updateTodo(_ todo: Domain.TodoVO) {
        
        let handleTodoResponse: MoyaResultHandler = { [self] result in
            switch result {
            case .success(let response):
                do {
                    let apiResp: APIResponse<TodoDTO> =
                        try response.mapAPIResponse(TodoDTO.self)
                    if let todo = apiResp.data {
                        realmKit.addData(todo)
                    }
                } catch {
                    print("디코딩 실패:", error)
                }
            case .failure(let error):
                print("통신 실패:", error)
            }
        }
        
        if let didLogin: Bool = ConfigManager.shared.get("didLogin"),
           didLogin {
            
            if todo.id.isEmpty {
                provider.request(.createTodo(todo: TodoDTO(from: todo))) { handleTodoResponse($0) }
            } else {
                
                let saved = realmKit.fetchData(type: TodoDTO.self, forKey: todo.id)!
                
                let title: String? = saved.title == todo.title ? nil : todo.title
                let isDone: Bool? = saved.isDone == todo.isDone ? nil : todo.isDone
                let endDate = saved.endDate == todo.endDate ? nil : todo.endDate
                let memo = saved.memo == todo.memo ? nil : todo.memo
                let color = saved.color == todo.color.toInt() ? nil : todo.color.toInt()
                let shared = Array(saved.shared) == todo.shared ? nil : todo.shared
                
                provider.request(.updateTodo(id: todo.id, title: title, isDone: isDone, endDate: endDate, memo: memo, color: color, shared: shared)) { handleTodoResponse($0) }
            }
            
        } else {
            
            let dto = TodoDTO(from:todo)
            
            if dto.id.isEmpty {
                dto.id = "local_\(UUID().hashValue)"
            }
            
            dto.updatedAt = Date()
            
            realmKit.addData(dto)
        }
    }
    
    public func updateDiary(_ diary: Domain.DiaryVO) {
        
        let handleDiaryResponse: MoyaResultHandler = { [self] result in
            switch result {
            case .success(let response):
                do {
                    let apiResp: APIResponse<DiaryDTO> =
                        try response.mapAPIResponse(DiaryDTO.self)
                    if let diary = apiResp.data {
                        realmKit.addData(diary)
                    }
                } catch {
                    print("디코딩 실패:", error)
                }
            case .failure(let error):
                print("통신 실패:", error)
            }
        }
        
        if let didLogin: Bool = ConfigManager.shared.get("didLogin"),
           didLogin {
            
            if diary.id.isEmpty {
                provider.request(.createDiary(diary: DiaryDTO(from: diary))) { handleDiaryResponse($0) }
            } else {
                
                let saved = realmKit.fetchData(type: DiaryDTO.self, forKey: diary.id)!
                
                let content: String? = saved.content == diary.content ? nil : diary.content
                let date = saved.date == diary.date ? nil : diary.date
                let shared = Array(saved.shared) == diary.shared ? nil : diary.shared
                
                provider.request(.updateDiary(id: diary.id, date: date, content: content, shared: shared)) { handleDiaryResponse($0) }
            }
            
        } else {
            
            let dto = DiaryDTO(from: diary)
            
            if dto.id.isEmpty {
                dto.id = "local_\(UUID().hashValue)"
            }
            
            dto.updatedAt = Date()
            
            realmKit.addData(dto)
        }
    }
    
    public func updateSchedule(_ schedule: Domain.ScheduleVO) {
        
        let handleScheduleResponse: MoyaResultHandler = { [self] result in
            switch result {
            case .success(let response):
                do {
                    let apiResp: APIResponse<ScheduleDTO> =
                        try response.mapAPIResponse(ScheduleDTO.self)
                    if let schedule = apiResp.data {
                        realmKit.addData(schedule)
                    }
                } catch {
                    print("디코딩 실패:", error)
                }
            case .failure(let error):
                print("통신 실패:", error)
            }
        }
        
        if let didLogin: Bool = ConfigManager.shared.get("didLogin"),
           didLogin {
            
            if schedule.id.isEmpty {
                provider.request(.createSchedule(schedule: ScheduleDTO(from: schedule))) { handleScheduleResponse($0) }
            } else {
                
                let saved = realmKit.fetchData(type: ScheduleDTO.self, forKey: schedule.id)!
                
                let title: String? = saved.title == schedule.title ? nil : schedule.title
                let startDate = saved.startDate == schedule.startDate ? nil : schedule.startDate
                let endDate = saved.endDate == schedule.endDate ? nil : schedule.endDate
                let memo = saved.memo == schedule.memo ? nil : schedule.memo
                let color = saved.color == schedule.color.toInt() ? nil : schedule.color.toInt()
                let shared = Array(saved.shared) == schedule.shared ? nil : schedule.shared
                
                provider.request(.updateSchedule(id: schedule.id, title: title, startDate: startDate, endDate: endDate, memo: memo, color: color, shared: shared)) { handleScheduleResponse($0) }
            }
            
        } else {
            
            let dto = ScheduleDTO(from: schedule)
            
            if dto.id.isEmpty {
                dto.id = "local_\(UUID().hashValue)"
            }
            
            dto.updatedAt = Date()
            
            realmKit.addData(dto)
        }
    }
    
    public func deleteTodo(_ id: String) {
        
        if !id.hasPrefix("local_") {
            if let didLogin: Bool = ConfigManager.shared.get("didLogin"),
               didLogin {
                provider.request(.deleteTodo(id: id)) { [self] result in
                    switch result {
                    case .success(let response):
                        if response.statusCode == 200 || response.statusCode == 204 {
                            realmKit.deleteData(TodoDTO.self, withId: id)
                        } else {
                            
                        }
                    case .failure(_): break
                        
                    }
                }
            } else {
                realmKit.deleteData(TodoDTO.self, withId: id)
                let op = CalendarOp(id: id, type: "todo", method: "delete")
                realmKit.addData(op)
            }
        } else {
            realmKit.deleteData(TodoDTO.self, withId: id)
        }
        
    }
    
    public func deleteDiary(_ id: String) {
        
        if !id.hasPrefix("local_") {
            if let didLogin: Bool = ConfigManager.shared.get("didLogin"),
               didLogin {
                provider.request(.deleteDiary(id: id)) { [self] result in
                    switch result {
                    case .success(let response):
                        if response.statusCode == 200 || response.statusCode == 204 {
                            realmKit.deleteData(DiaryDTO.self, withId: id)
                        } else {
                            
                        }
                    case .failure(_): break
                        
                    }
                }
            } else {
                realmKit.deleteData(DiaryDTO.self, withId: id)
                let op = CalendarOp(id: id, type: "diary", method: "delete")
                realmKit.addData(op)
            }
        } else {
            realmKit.deleteData(DiaryDTO.self, withId: id)
        }
        
    }
    
    public func deleteSchedule(_ id: String) {
        
        if !id.hasPrefix("local_") {
            if let didLogin: Bool = ConfigManager.shared.get("didLogin"),
               didLogin {
                provider.request(.deleteSchedule(id: id)) { [self] result in
                    switch result {
                    case .success(let response):
                        if response.statusCode == 200 || response.statusCode == 204 {
                            realmKit.deleteData(ScheduleDTO.self, withId: id)
                        } else {
                            
                        }
                    case .failure(_): break
                        
                    }
                }
            } else {
                realmKit.deleteData(ScheduleDTO.self, withId: id)
                let op = CalendarOp(id: id, type: "todo", method: "delete")
                realmKit.addData(op)
            }
        } else {
            realmKit.deleteData(ScheduleDTO.self, withId: id)
        }
        
    }
    
    public func syncServer() {
        
        let lastDate = authManager.lastLoginDate()
        
        let localPrefix = "local_"
        
        let ops = realmKit.fetchAllData(type: CalendarOp.self)
            .toArray()
        
        let todos = realmKit.fetchAllData(type: TodoDTO.self)
            .filter("NOT id BEGINSWITH %@ AND updatedAt > %@", localPrefix, lastDate)
            .toArray()
        
        let delTodos = realmKit.fetchAllData(type: TodoDTO.self)
            .filter("id BEGINSWITH %@", localPrefix)
            .toArray()
        
        let schedules = realmKit.fetchAllData(type: ScheduleDTO.self)
            .filter("NOT id BEGINSWITH %@ AND updatedAt > %@", localPrefix, lastDate)
            .toArray()
        
        let delSchedules = realmKit.fetchAllData(type: ScheduleDTO.self)
            .filter("id BEGINSWITH %@", localPrefix)
            .toArray()
        
        let diaries = realmKit.fetchAllData(type: DiaryDTO.self)
            .filter("NOT id BEGINSWITH %@ AND updatedAt > %@", localPrefix, lastDate)
            .toArray()
        
        let delDiaries = realmKit.fetchAllData(type: DiaryDTO.self)
            .filter("id BEGINSWITH %@", localPrefix)
            .toArray()
        
        provider.request(.sync(ops: ops, todos: todos + delTodos, schedules: schedules + delSchedules, diaries: diaries + delDiaries)) { [self] result in
            switch result {
            case .success(let resp):
                
                do {
                    let apiResp: APIResponse<CalendarDTO> =
                    try resp.mapAPIResponse(CalendarDTO.self)
                    
                    if apiResp.success {
                        realmKit.deleteDatas(ops)
                        realmKit.deleteDatas(delTodos)
                        realmKit.deleteDatas(delDiaries)
                        realmKit.deleteDatas(delSchedules)
                        
                        if let schedules = apiResp.data?.schedules {
                            realmKit.addDatas(schedules)
                        }
                        
                        if let todos = apiResp.data?.todos {
                            realmKit.addDatas(todos)
                        }
                        
                        if let diaries = apiResp.data?.diaries {
                            realmKit.addDatas(diaries)
                        }
                    }
                } catch {
                    print(error)
                }
                break
            case .failure(let err):
                print(err);
                break
            }
        }
    }
    
    private func gridStartAndEnd(for monthDate: Date) -> (start: Date, end: Date) {
        
        let calendar = Calendar.current
        
        let comps = calendar.dateComponents([.year, .month], from: monthDate)
        let firstOfMonth = calendar.date(from: comps)!

        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        let prefixDays = (weekdayOfFirst - calendar.firstWeekday + 7) % 7

        let daysInMonth = calendar.range(of: .day, in: .month, for: monthDate)!.count

        let totalSlots = Int(ceil(Double(prefixDays + daysInMonth) / 7.0)) * 7

        let gridStart = calendar.date(byAdding: .day, value: -prefixDays, to: firstOfMonth)!

        let gridEnd = calendar.date(byAdding: .day, value: totalSlots, to: gridStart)!

        return (start: gridStart, end: gridEnd)
      }
    
}

private enum CalendarRepoKey: DependencyKey {
    static var liveValue: CalendarRepository = CalendarRepositoryImpl()
    static var testValue: CalendarRepository = CalendarRepositoryImpl()
}

public extension DependencyValues {
    var calendarRepository: CalendarRepository {
        get { self[CalendarRepoKey.self] }
        set { self[CalendarRepoKey.self] = newValue }
    }
}

extension Results {
    func toArray() -> [Element] {
        return Array(self)
    }
}
