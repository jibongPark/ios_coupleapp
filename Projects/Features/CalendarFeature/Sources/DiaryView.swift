import Foundation
import SwiftUI
import ComposableArchitecture


public struct DiaryView : View {
    
    @Bindable var store: StoreOf<DiaryReducer>
    
    public init(store: StoreOf<DiaryReducer>) {
        self.store = store
    }
    
    public var body: some View {
        VStack {
            Spacer()
            
            TextEditor(text: $store.content)
                .overlay(alignment: .center) {
                    if(store.content.isEmpty) {
                        Text("내용을 입력해 주세요")
                            .foregroundStyle(store.content.isEmpty ? .gray.opacity(0.5) : .clear)
                    }
                }
        }
        .toolbar {
            
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text("일기")
                    Text(store.date.formattedCalendarDayDate)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("저장") {
                    store.send(.confirmButtonTapped)
                }
            }
        }
    }
}

#Preview {
    DiaryView(
        store: Store(initialState: DiaryReducer.State(date: Date())) {
            DiaryReducer()
        }
    )
}
