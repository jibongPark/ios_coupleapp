//
//  InfinitePagerView.swift
//  CalendarFeature
//
//  Created by 박지봉 on 3/24/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import SwiftUI

internal struct InfinitePagerView<C>: View where C: View {
    var selection: Date
    
    let before: (Date) -> Date
    let after: (Date) -> Date
    let selectDate: Date
    
    let onDisapearCompletion: (Date) -> Void
    
    @ViewBuilder let view: (Date) -> C
    
    @State private var currentTab: Int = 0
    
    
    var body: some View {
        let previusIndex = before(selection)
        let nextIndex = after(selection)
        
        TabView(selection: $currentTab) {
            view(previusIndex)
                .tag(-1)
            
            view(selection)
                .onDisappear() {
                    if currentTab != 0 {
                        onDisapearCompletion(currentTab < 0 ? previusIndex : nextIndex)
                        currentTab = 0
                    }
                }
                .tag(0)
            
            view(nextIndex)
                .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .disabled(currentTab != 0) // FIXME: workaround to avoid glitch when swiping twice very quickly
        .onChange(of: selectDate) { oldValue, newValue in
            
            if currentTab == 0 {
                if newValue.month == after(oldValue).month {
                    withAnimation(.easeInOut) {
                        currentTab = 1
                    }
                } else if newValue.month == before(oldValue).month {
                    withAnimation(.easeInOut) {
                        currentTab = -1
                    }
                }
            }
        }
    }
}
