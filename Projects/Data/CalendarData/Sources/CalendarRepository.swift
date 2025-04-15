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


public struct CalendarRepositoryImpl: CalendarRepository {
    
    @Dependency(\.realmKit) var realmKit
    
    public init() {}
    
    public func fetchTodo(ofMonth: Date) -> ComposableArchitecture.Effect<[String : [Domain.TodoVO]]> {
        
        let schemaVersion: UInt64 = 3
        
        let config = Realm.Configuration(
            schemaVersion: schemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < schemaVersion {
                    migration.enumerateObjects(ofType: ScheduleDTO.className()) { oldObject, newObject in
                        newObject?["color"] = 0
                    }
                    
                    migration.enumerateObjects(ofType: TodoDTO.className()) { oldObject, newObject in
                        newObject?["color"] = 0
                    }
                }
            }
        )
        Realm.Configuration.defaultConfiguration = config
        
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.year, .month], from: ofMonth)
        
        let year = components.year
        let month = components.month
        
        let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1, hour: 0, minute: 0, second: 0))!
        
        let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        
        return .run { send in
            let todos = realmKit.fetchAllData(type: TodoDTO.self)
                .filter("endDate >= %@ AND endDate < %@", startOfMonth, startOfNextMonth)
            
            let todoDTOs = Dictionary(grouping: todos) { todo in
                todo.endDate.calendarKeyString
            }
            
            let todoVOs = todoDTOs.mapValues { dtoArray in
                dtoArray.map { $0.toVO() }
            }
            
            await send(todoVOs)
        }
    }
    
    public func fetchDiary(ofMonth: Date) -> ComposableArchitecture.Effect<[String : Domain.DiaryVO]> {
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.year, .month], from: ofMonth)
        
        let year = components.year
        let month = components.month
        
        let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1, hour: 0, minute: 0, second: 0))!
        
        let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        
        return .run { send in
            let diaries = realmKit.fetchAllData(type: DiaryDTO.self)
                .filter("date >= %@ AND date < %@", startOfMonth.calendarKeyString, startOfNextMonth.calendarKeyString)
            
            let diariesDic = Dictionary(uniqueKeysWithValues:diaries.map { ($0.date, $0.toVO()) })
            
            await send(diariesDic)
        }
    }
    
    public func fetchSchedule(ofMonth: Date) -> ComposableArchitecture.Effect<[String : [Domain.ScheduleVO]]> {
        
            let calendar = Calendar.current
            
            let components = calendar.dateComponents([.year, .month], from: ofMonth)
            
            let year = components.year
            let month = components.month
            
            let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1, hour: 0, minute: 0, second: 0))!
            
            let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            
            
            return .run { send in
                let schedules = realmKit.fetchAllData(type: ScheduleDTO.self)
                    .filter("endDate >= %@ AND startDate < %@", startOfMonth, startOfNextMonth)
                
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
                
                await send(scheduleVOs)
            }
    }
    
    public func updateTodo(_ todo: Domain.TodoVO) {
        realmKit.addData(TodoDTO(from:todo))
    }
    
    public func updateDiary(_ diary: Domain.DiaryVO) {
        realmKit.addData(DiaryDTO(from: diary))
    }
    
    public func updateSchedule(_ schedule: Domain.ScheduleVO) {
        realmKit.addData(ScheduleDTO(from: schedule))
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
