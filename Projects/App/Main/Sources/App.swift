//
//  App.swift
//  coupleapp
//
//  Created by 박지봉 on 3/20/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

@main
struct MyApp: App {
    
    static let store = Store(initialState: AppReducer.State()) {
        AppReducer()
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(store: MyApp.store)
        }
    }
}
