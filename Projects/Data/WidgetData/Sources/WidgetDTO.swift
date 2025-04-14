//
//  WidgetDTO.swift
//  MapData
//
//  Created by 박지봉 on 4/10/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import Domain
import SwiftUICore

final class WidgetDTO {
    
    public init(id: Int = UUID().hashValue, title: String = "", memo: String = "", startDate: Date = Date(), imagePath: String = "", isShowDate: Bool = true, dateAlignment: Alignment, isShowTitle: Bool = true, titleAlignment: Alignment) {
        self.id = id
        self.title = title
        self.memo = memo
        self.startDate = startDate
        self.imagePath = imagePath
        self.isShowDate = isShowDate
        self.dateAlignment = dateAlignment
        self.isShowTitle = isShowTitle
        self.titleAlignment = titleAlignment
    }
    
    public let id: Int
    public let title: String
    public let memo: String
    public let startDate: Date
    public let imagePath: String
    public let isShowDate: Bool
    public let dateAlignment: Alignment
    public let isShowTitle: Bool
    public let titleAlignment: Alignment
    
}

