import ComposableArchitecture
import Domain
import Testing
@testable import WidgetFeature

@MainActor
struct WidgetReducerTests {
    @Test
    func didTapAddDDayButtonPresentsAddDDay() async {
        let store = TestStore(initialState: WidgetReducer.State()) {
            WidgetReducer()
        }

        await store.send(.didTapAddDDayButton) { state in
            state.destination = .addDdayView(AddDDayReducer.State())
        }
    }

    @Test
    func selectingWidgetWhileEditingTogglesSelection() async {
        let widget = WidgetVO(id: 1, title: "기념일")
        var state = WidgetReducer.State()
        state.isEditing = true
        state.widgetData = [widget]
        let store = TestStore(initialState: state) {
            WidgetReducer()
        }

        await store.send(.didTapWidgetData(widget)) { state in
            state.selectedWidget = [1]
        }

        await store.send(.didTapWidgetData(widget)) { state in
            state.selectedWidget = []
        }
    }
}
