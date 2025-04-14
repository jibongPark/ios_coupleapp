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

public enum WidgetAlign: Equatable, Codable {
    case topLeft
    case topCenter
    case topRight
    case centerLeft
    case center
    case centerRight
    case bottomLeft
    case bottomCenter
    case bottomRight
}

public extension WidgetAlign {
    func toTextAlignment() -> Alignment {
        switch self {
            
        case .topLeft:
            return .topLeading
        case .topCenter:
            return .top
        case .topRight:
            return .topTrailing
            
        case .centerLeft:
            return .leading
        case .center:
            return .center
        case .centerRight:
            return .trailing
            
        case .bottomLeft:
            return .bottomLeading
        case .bottomCenter:
            return .bottom
        case .bottomRight:
            return .bottomTrailing
            
        }
    }
}

public extension Alignment {
    func toWidgetAlignment() -> WidgetAlign {
        switch self {
            
        case .topLeading:
            return .topLeft
        case .top:
            return .topCenter
        case .topTrailing:
            return .topRight
            
        case .leading:
            return .centerLeft
        case .center:
            return .center
        case .trailing:
            return .centerRight
            
        case .bottomLeading:
            return .bottomLeft
        case .bottom:
            return .bottomCenter
        case .bottomTrailing:
            return .bottomRight
            
        default:
            return .center
        }
    }
}


public struct WidgetVO: Identifiable, Equatable, Codable {
    
    public init(id: Int = UUID().hashValue, title: String = "", memo: String = "", startDate: Date = Date(), imagePath: String = "", isShowDate: Bool = true, dateAlignment: Alignment = .center, isShowTitle: Bool = true, titleAlignment: Alignment = .center) {
        self.id = id
        self.title = title
        self.memo = memo
        self.startDate = startDate
        self.imagePath = imagePath
        self.isShowDate = isShowDate
        self.dateAlignment = dateAlignment.toWidgetAlignment()
        self.isShowTitle = isShowTitle
        self.titleAlignment = titleAlignment.toWidgetAlignment()
    }
    
    public let id: Int
    public let title: String
    public let memo: String
    public let startDate: Date
    public let imagePath: String
    public let isShowDate: Bool
    public let dateAlignment: WidgetAlign
    public let isShowTitle: Bool
    public let titleAlignment: WidgetAlign
    
}

public extension Date {
    var dDayString: String {
        let calendar = Calendar.current
        
        let startOfGivenDate = calendar.startOfDay(for: self)
        let startOfToday = calendar.startOfDay(for: Date())
        
        let components = calendar.dateComponents([.day], from: startOfGivenDate, to: startOfToday)
        let dayCount = components.day ?? 0
        
        return dayCount < 0 ? "\(-dayCount)일 전" : "\(dayCount+1)일"
    }
}
