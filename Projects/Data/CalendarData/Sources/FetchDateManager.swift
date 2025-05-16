//
//  FetchDateManager.swift
//  CalendarData
//
//  Created by 박지봉 on 5/16/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation

typealias LastFetchDates = [String: TimeInterval]

struct FetchDateManager {
    private let key = "lastFetchDates"
    private let userDefaults = UserDefaults.standard
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMM"
        return f
    }()
    
    private var allDates: LastFetchDates {
        get {
            userDefaults.dictionary(forKey: key) as? LastFetchDates ?? [:]
        }
        set {
            userDefaults.set(newValue, forKey: key)
        }
    }
    
    func lastFetch(for date: Date) -> Date? {
        let ym = formatter.string(from: date)
        guard let time = allDates[ym] else { return nil }
        return Date(timeIntervalSince1970: time)
    }
    
    mutating func updateLastFetch(_ date: Date) {
        let ym = formatter.string(from: date)
        allDates[ym] = Date().timeIntervalSince1970
    }
}
