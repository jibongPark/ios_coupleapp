import Foundation
import SwiftUI
import ComposableArchitecture


struct TodoView : View {
    
    @Bindable var store: StoreOf<TodoReducer>
    
    init(store: StoreOf<TodoReducer>) {
        self.store = store
    }
    
    var body: some View {
        VStack {
            Divider()
            
            VStack(spacing: 10) {
                
                HStack {
                    TextField("할 일을 입력하세요.", text: $store.title)
                        .font(.title2.bold())
                    
                    ColorPicker("", selection: $store.color)
                        .frame(maxWidth: 50)
                }
                
                Divider()
                HStack {
                    DatePicker("종료일", selection: $store.date, displayedComponents: [.date])
                    Text(" 까지")
                }
                
                TextEditor(text: $store.content)
                    .overlay(alignment: .topLeading) {
                        Text("설명을 입력하세요.")
                            .foregroundStyle(store.content.isEmpty ? .gray.opacity(0.5) : .clear)
                            .padding(5)
                    }
            }
            .padding(15)
        }
        
        .toolbar {
            
            ToolbarItem(placement: .principal) {
                Text("할 일")
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
    
    TodoView(store: Store(initialState: TodoReducer.State(date: Date())) {
        TodoReducer()
    })
}
