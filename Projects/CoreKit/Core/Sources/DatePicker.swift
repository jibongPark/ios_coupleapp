//
//  DatePicker.swift
//  Core
//
//  Created by 박지봉 on 4/11/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
public struct DatePickerReducer {
    public init() {
        
    }
    
    public enum pickerType: Equatable {
        case wheel
        case calendar
    }
    
    @ObservableState
    public struct State: Equatable {
        public init() {}
        
        public init(date: Date) {
            self.selectedDate = date
        }
        
        
        public var selectedDate: Date = Date()
        var pickerType: pickerType = .wheel
        
    }
    
    public enum Action: BindableAction {
        
        case typeChangeButtonTapped
        case okButtonTapped(Date)
        
        case binding(BindingAction<State>)
        
        case delegate(Delegate)
        public enum Delegate: Equatable {
            case didFinishPicking(date: Date)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    public var body: some ReducerOf<Self> {
        
        BindingReducer()
        
        Reduce { state, action in
            switch action {
                
            case .okButtonTapped(let date):
                return .run { [date] send in
                    await send(.delegate(.didFinishPicking(date: date)))
                    await self.dismiss()
                }
                
            case .typeChangeButtonTapped:
                    switch state.pickerType {
                    case .wheel:
                        state.pickerType = .calendar
                        
                    case .calendar:
                        state.pickerType = .wheel
                    }
                return .none
                
            case .delegate:
                return .none
                
            case .binding:
                return .none
            }
        }
    }
}

public struct DatePickerView: View {
    
    public init(store: StoreOf<DatePickerReducer>) {
        self.store = store
    }
    
    @Bindable var store: StoreOf<DatePickerReducer>
    
    public var body: some View {
        VStack (alignment: .leading, spacing: 0) {
            
            HStack(spacing: 0) {
                Button(action: {
                    store.send(.typeChangeButtonTapped)
                }) {
                    
                    switch store.pickerType {
                        
                    case .wheel:
                        Image(systemName: "calendar")
                            .resizable()
                            .scaledToFill()
                        
                    case .calendar:
                        Image(systemName: "arrowshape.backward")
                            .resizable()
                            .scaledToFill()
                    }
                }
                .foregroundColor(.gray)
                .frame(width: 20, height: 20, alignment: .leading)
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 2, trailing: 2))
                
                Spacer()
            }
            
            switch store.pickerType {
                
            case .wheel:
                DatePicker("", selection: $store.selectedDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(WheelDatePickerStyle())
                    .frame(maxWidth: .infinity)
                    .padding(10)
                
            case .calendar:
                DatePicker("", selection: $store.selectedDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .frame(maxWidth: .infinity)
                    .padding(10)
                
            }
            
            HStack(alignment: .center) {
                Button(action: {
                    store.send(.okButtonTapped(store.selectedDate))
                }) {
                    Text("확인")
                }
                .frame(height: 30)
                .frame(maxWidth: .infinity)
            }
            .padding(10)
        }
    }
}


#Preview {
    DatePickerView(store: Store(initialState: DatePickerReducer.State()) {
        DatePickerReducer()
    })
}
