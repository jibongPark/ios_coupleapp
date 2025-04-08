import Foundation
import SwiftUI
import ComposableArchitecture


public struct ScheduleView : View {
    
    @Bindable var store: StoreOf<ScheduleReducer>
    
    public init(store: StoreOf<ScheduleReducer>) {
        self.store = store
    }
    
    public var body: some View {
        
        VStack {
            Divider()
            
            HStack {
                TextField("일정을 입력하세요.", text: $store.title)
                    .font(.title2.bold())
                
                ColorPicker("", selection: $store.color)
                    .frame(maxWidth: 50)
            }
            Divider()
            
            DatePicker("시작일", selection: $store.startDate, displayedComponents: [.date, .hourAndMinute])
            DatePicker("종료일", selection: $store.endDate, in: store.startDate..., displayedComponents: [.date, .hourAndMinute])
            
            TextEditor(text: $store.content)
                .overlay(alignment: .topLeading) {
                    Text("설명을 입력하세요.")
                        .foregroundStyle(store.content.isEmpty ? .gray.opacity(0.5) : .clear)
                        .padding(5)
                }
        }
        .padding(5)
        .toolbar {
            
            ToolbarItem(placement: .principal) {
                Text("일정")
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("저장") {
                    store.send(.saveButtonTapped)
                }
            }
        }
    }
}

#Preview {
    ScheduleView(
        store: Store(initialState: ScheduleReducer.State()) {
            ScheduleReducer()
        }
    )
}
