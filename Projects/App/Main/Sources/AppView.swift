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
                    Image(systemName: "map")
                    Text("여행지도")
                }
            AnyView(calendarFeature.makeView())
                .tabItem {
                    Image(systemName: "calendar")
                    Text("캘린더")
                }
            AnyView(widgetFeature.makeView())
                .tabItem {
                    Image(systemName: "widget.small")
                    Text("위젯")
                }
        }
        .onAppear() {
            UITabBar.appearance().scrollEdgeAppearance = .init()
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
