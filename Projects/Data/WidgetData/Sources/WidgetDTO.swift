//
//  WidgetDTO.swift
//  MapData
//
//  Created by 박지봉 on 4/10/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import Domain

final class WidgetDTO {
    
    public init(id: Int = UUID().hashValue, title: String = "", memo: String = "", startDate: Date = Date(), imagePath: String = "", alignment: WidgetAlign = .center) {
        self.id = id
        self.title = title
        self.memo = memo
        self.startDate = startDate
        self.imagePath = imagePath
        self.alignment = alignment
    }
    
    public let id: Int
    public let title: String
    public let memo: String
    public let startDate: Date
    public let imagePath: String
    public let alignment: WidgetAlign
    
}

