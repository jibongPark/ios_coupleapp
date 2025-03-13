//
//  TestProject.swift
//  TestProject
//
//  Created by Junyoung on 1/8/25.
//

import SwiftUI

import ComposableArchitecture
import CalendarFeature

@main
struct TestProject: App {
    var body: some Scene {
        WindowGroup {
            CalendarView(
                store: Store(initialState: CalendarReducer.State(selectedMonth: Date())) {
                    CalendarReducer()
                }
            )
        }
    }
}
