//
//  AppIntent.swift
//  coupleapp.WidgetExtension
//
//  Created by 박지봉 on 4/9/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import WidgetKit
import AppIntents
import SwiftUI

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    
    @Parameter(title: "Widget Item")
    var selectedItem: WidgetEntity?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$selectedItem)")
    }
    
    init() {}
    
    init(selectedItem: WidgetEntity) {
        self.selectedItem = selectedItem
    }
}
