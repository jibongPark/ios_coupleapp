//
//  TestProject.swift
//  TestProject
//
//  Created by Junyoung on 1/8/25.
//

import SwiftUI
import ComposableArchitecture
import MapFeature
import CalendarFeature
import WidgetFeature

struct AppView: View {
    
    @Dependency(\.mapFeature) var mapFeature
    @Dependency(\.calendarFeature) var calendarFeature
    @Dependency(\.widgetFeature) var widgetFeature
    
    let store: StoreOf<AppReducer>
    
    var body: some View {
        
        TabView {
            
            AnyView(mapFeature.makeView())
                .tabItem {
                    Text("여행지도")
                }
            AnyView(calendarFeature.makeView())
                .tabItem {
                    Text("캘린더")
                }
            AnyView(widgetFeature.makeView())
                .tabItem {
                    Text("위젯")
                }
        }
    }
}

@Reducer
struct AppReducer {
    
    struct State: Equatable {
    }
    
    struct Action {
        
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            return .none
        }
    }
}
