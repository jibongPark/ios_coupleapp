//
//  Extension.swift
//  CalendarFeature
//
//  Created by 박지봉 on 3/24/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import SwiftUICore

extension Date {
    
    static let calendarDayDateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "YYYY M d"
      return formatter
    }()
    
    static let calendarHeaderDateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "YYYY.MM"
      return formatter
    }()
    
    func addMonth(_ value: Int) -> Date {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: self) {
            return newMonth
        }
        
        return self
    }
    
    func getDate(for index: Int) -> Date {
      let calendar = Calendar.current
      guard let firstDayOfMonth = calendar.date(
        from: DateComponents(
          year: calendar.component(.year, from: self),
          month: calendar.component(.month, from: self),
          day: 1
        )
      ) else {
        return Date()
      }
      
      var dateComponents = DateComponents()
      dateComponents.day = index
      
      let timeZone = TimeZone.current
      let offset = Double(timeZone.secondsFromGMT(for: firstDayOfMonth))
      dateComponents.second = Int(offset)
      
      let date = calendar.date(byAdding: dateComponents, to: firstDayOfMonth) ?? Date()
      return date
    }
    
    func isToday() -> Bool {
        return self.formattedCalendarDayDate == Date().formattedCalendarDayDate
    }
    
    func isEqualTo(month date: Date) -> Bool {
        return self.year == date.year && self.month == date.month
    }
    
    func isEqual(to date: Date) -> Bool {
        return self.formattedCalendarDayDate == date.formattedCalendarDayDate
    }
    
    var formattedCalendarDayDate: String {
      return Date.calendarDayDateFormatter.string(from: self)
    }
    
    var formattedCalendarMonthDate: String {
        return Date.calendarHeaderDateFormatter.string(from: self)
    }
    
    var day: Int {
        return Calendar.current.component(.day, from: self)
    }
    
    var month: Int {
        return Calendar.current.component(.month, from: self)
    }
    
    var year: Int {
        return Calendar.current.component(.year, from: self)
    }
    
    var weekDay: String {
        let weekDays: [String] = Calendar.current.shortWeekdaySymbols
        
        return weekDays[Calendar.current.component(.weekday, from: self) - 1]
    }
    
    func isSunday() -> Bool {
        return Calendar.current.component(.weekday, from: self) == 1
    }
    
    
    
}
