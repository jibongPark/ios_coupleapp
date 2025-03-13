import Foundation
import SwiftUI
import ComposableArchitecture


public struct DiaryView : View {
    
    let store: StoreOf<DiaryReducer>
    
    public init(store: StoreOf<DiaryReducer>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack {
                Spacer()
                Text("diary")
                HStack {
                    Button(
                        action: { },
                        label: {
                            Text("Confirm")
                        }
                    )
                }
                Spacer()
                Text("date")
                Spacer()
                TextEditor(text: viewStore.$content)
                    .overlay(alignment: .topLeading) {
                        Text("내용을 입력해 주세요")
                            .foregroundStyle(viewStore.content.isEmpty ? .gray : .clear)
                    }
                    
            }
        }
    }
}

struct DiaryView_Previews: PreviewProvider {
    static var previews: some View {
        DiaryView(
            store: Store(initialState: DiaryReducer.State(date: Date())) {
                DiaryReducer()
            }
        )
    }
}
