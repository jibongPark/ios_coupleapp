//
//  CalendarService.swift
//  CalendarData
//
//  Created by 박지봉 on 5/13/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Moya
import Foundation
import Domain

enum CalendarAPI {
    case calendar(startDate: String, endDate: String, lastFetch: String)
    
    case createTodo(todo: TodoDTO)
    case updateTodo(id: String, title: String?, isDone: Bool?, endDate: Date?, memo: String?, color: Int?, shared: [String]?)
    case deleteTodo(id: String)

    case createSchedule(schedule: ScheduleDTO)
    case updateSchedule(id: String, title: String?, startDate: Date?, endDate: Date?, memo: String?, color: Int?, shared: [String]?)
    case deleteSchedule(id: String)
    
    case createDiary(diary: DiaryDTO)
    case updateDiary(id: String, date: Date?, content: String?, shared: [String]?)
    case deleteDiary(id: String)
}

extension CalendarAPI: TargetType {
    
    var headers: [String : String]? {
        ["Content-Type": "application/json"]
    }
    
    var baseURL: URL {
        let url = Bundle.main.object(forInfoDictionaryKey:"BASE_URL")
        
        if let urlString = url as? String {
            return URL(string: urlString)!
        } else {
            fatalError("URL String not found")
        }
    }
    
    var path: String {
        switch self {
        case .calendar:
              return "/calendar"
        case .createTodo:
            return "/todo"
        case .updateTodo(let id, _, _, _, _, _, _), .deleteTodo(let id):
            return "/todo/\(id)"
        case .createSchedule:
            return "/schedule"
        case .updateSchedule(let id, _, _, _, _, _, _), .deleteSchedule(let id):
            return "/schedule/\(id)"
        case .createDiary:
            return "/diary"
        case .updateDiary(let id, _, _, _), .deleteDiary(let id):
            return "/diary/\(id)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .calendar:
            return .get
        case .createTodo:
            return .post
        case .updateTodo:
            return .patch
        case .deleteTodo:
            return .delete
        case .createSchedule:
            return .post
        case .updateSchedule:
            return .patch
        case .deleteSchedule:
            return .delete
        case .createDiary:
            return .post
        case .updateDiary:
            return .patch
        case .deleteDiary:
            return .delete
        }
    }
//    (id: String, date: Date, content: String, shared: [String])
    
    var task: Task {
        switch self {
        case let .calendar(startDate, endDate, lastFetch):
            return .requestParameters(parameters: ["startDate": startDate, "endDate": endDate, "lastFetch": lastFetch], encoding: URLEncoding.default)
            
        case let .createTodo(todo):
            
            return .requestParameters(parameters: ["title": todo.title,
                                                   "isDone": todo.isDone,
                                                   "endDate": ISO8601DateFormatter().string(from: todo.endDate),
                                                   "memo": todo.memo,
                                                   "color": todo.color,
                                                   "shared": Array(todo.shared)],
                                      encoding: JSONEncoding.default)
            
        case let .updateTodo(_, title, isDone, endDate, memo, color, shared):
            
            let params: [String: Any?] = ["title": title,
                                          "isDone": isDone,
                                          "endDate": endDate,
                                          "memo": memo,
                                          "color": color,
                                          "shared": shared]
            let filtered: [String: Any] = params.compactMapValues { maybe in
                guard let v = maybe else { return nil }
                
                if let d = v as? Date {
                    return ISO8601DateFormatter().string(from: d)
                }
                
                return v
            }
            
            return .requestParameters(parameters: filtered, encoding: JSONEncoding.default)
            
        case .deleteTodo:
            return .requestPlain
            
        case let .createSchedule(schedule):
            return .requestParameters(parameters: ["title": schedule.title,
                                                   "startDate": ISO8601DateFormatter().string(from: schedule.startDate),
                                                   "endDate": ISO8601DateFormatter().string(from: schedule.endDate),
                                                   "memo": schedule.memo,
                                                   "color": schedule.color,
                                                   "shared": Array(schedule.shared)],
                                      encoding: JSONEncoding.default)
            
        case let .updateSchedule(_, title, startDate, endDate, memo, color, shared):
            
            let params: [String: Any?] = ["title": title,
                                          "startDate": startDate,
                                          "endDate": endDate,
                                          "memo": memo,
                                          "color": color,
                                          "shared": shared]
            
            let filtered: [String: Any] = params.compactMapValues { maybe in
                guard let v = maybe else { return nil }
                
                if let d = v as? Date {
                    return ISO8601DateFormatter().string(from: d)
                }
                
                return v
            }
            
            return .requestParameters(parameters: filtered, encoding: JSONEncoding.default)
            
        case .deleteSchedule:
            return .requestPlain
            
        case let .createDiary(diary):
            return .requestParameters(parameters: ["date": ISO8601DateFormatter().string(from: diary.date),
                                                   "content": diary.content,
                                                   "shared": Array(diary.shared)],
                                      encoding: JSONEncoding.default)
            
        case let .updateDiary(_, date, content, shared):
            let params: [String: Any?] = ["date": date,
                                          "content": content,
                                          "shared": shared]
            
            let filtered: [String: Any] = params.compactMapValues { maybe in
                guard let v = maybe else { return nil }
                
                if let d = v as? Date {
                    return ISO8601DateFormatter().string(from: d)
                }
                
                return v
            }
            
            return .requestParameters(parameters: filtered, encoding: JSONEncoding.default)
            
        case .deleteDiary:
            return .requestPlain
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var validationType: ValidationType {
        return .successCodes
    }
}
