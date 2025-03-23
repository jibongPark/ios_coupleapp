//
//  TestProject.swift
//  TestProject
//
//  Created by Junyoung on 1/8/25.
//

import SwiftUI
import ComposableArchitecture
import MapFeature

//@main
struct AppView: View {
    
    @Dependency(\.mapFeature) var mapFeature
    
    let store: StoreOf<AppReducer>
    
    var body: some View {
        
        TabView {
            
            AnyView(mapFeature.makeView())
                .tabItem {
                    Text("지도")
                }
            
        }
    }
}

@Reducer
struct AppReducer {
    
    struct State: Equatable {
//        var
    }
    
    struct Action {
        
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            return .none
        }
    }
}
