//
//  CalendarRepository.swift
//  Domain
//
//  Created by 박지봉 on 3/25/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import ComposableArchitecture
import Foundation

public protocol WidgetRepository: Sendable {
    
    func fetchWidgetTCA() -> Effect<[WidgetVO]>
    func fetchWidget() -> [WidgetVO]
    
    func updateWidget(_ widget: WidgetVO) async
    func removeWidget(_ value: WidgetVO) async
}
