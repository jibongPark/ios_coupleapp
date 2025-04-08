//
//  CalendarVO.swift
//  Domain
//
//  Created by 박지봉 on 3/25/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import SwiftUICore
import UIKit

enum CalendarDataType: Equatable {
    case todo
    case diary
    case schedule
}

public protocol CalendarVO {
    var id: Int { get }
    var title: String { get }
    
    var startDate: Date { get }
    var endDate: Date { get }
    var color: Color { get }
}

public struct TodoVO: Identifiable, Equatable, Hashable, CalendarVO {
    
    public init(id: Int = UUID().hashValue, title: String = "", memo: String = "", endDate: Date = Date(), isDone: Bool = false, color: Color) {
        self.id = id
        self.title = title
        self.memo = memo
        self.endDate = endDate
        self.isDone = isDone
        self.color = color
    }
    
    public let id: Int
    public let title: String
    public let memo: String
    public let endDate: Date
    public var isDone: Bool
    public var color: Color
    
    public var startDate: Date { endDate }
}

public struct ScheduleVO: Identifiable, Equatable, CalendarVO {
    
    public init(id: Int = UUID().hashValue, title: String, startDate: Date, endDate: Date, memo: String, color: Color) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.memo = memo
        self.color = color
    }
    
    public var id: Int
    public var title: String
    public var startDate: Date
    public var endDate: Date
    public var memo: String
    public var color: Color
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

public extension UIColor {
    
    convenience init(hex: String) {
        let trimHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let dropHash = String(trimHex.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        let hexString = trimHex.starts(with: "#") ? dropHash : trimHex
        let ui64 = UInt64(hexString, radix: 16)
        let value = ui64 != nil ? Int(ui64!) : 0
        // #RRGGBB
        var components = (
            R: CGFloat((value >> 16) & 0xff) / 255,
            G: CGFloat((value >> 08) & 0xff) / 255,
            B: CGFloat((value >> 00) & 0xff) / 255,
            a: CGFloat(1)
        )
        if String(hexString).count == 8 {
            // #RRGGBBAA
            components = (
                R: CGFloat((value >> 24) & 0xff) / 255,
                G: CGFloat((value >> 16) & 0xff) / 255,
                B: CGFloat((value >> 08) & 0xff) / 255,
                a: CGFloat((value >> 00) & 0xff) / 255
            )
        }
        self.init(red: components.R, green: components.G, blue: components.B, alpha: components.a)
    }
    
    func toHex(alpha: Bool = false) -> String? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if alpha {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}

extension Color {
    public init(hex: String) {
        self.init(UIColor(hex: hex))
    }
    
    public init(int: Int) {
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(Color(red: r, green: g, blue: b, opacity: 1.0))
    }
    

    public func toHex(alpha: Bool = false) -> String {
        UIColor(self).toHex(alpha: alpha) ?? ""
    }
    
    public func toInt() -> Int {
        var hex = self.toHex()
        
        if hex.hasPrefix("0x") || hex.hasPrefix("0X") {
            hex = String(hex.dropFirst(2))
        }

        // 16진수(radix: 16)를 사용해 문자열을 Int로 변환합니다.
        if let intValue = Int(hex, radix: 16) {
            return intValue
        } else {
            return 0
        }
    }
}
