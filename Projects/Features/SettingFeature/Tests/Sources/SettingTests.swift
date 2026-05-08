import ComposableArchitecture
import Testing
@testable import SettingFeature

@MainActor
struct SettingTests {
    @Test
    func onAppearDoesNotMutateDisplayState() async {
        let store = TestStore(initialState: SettingReducer.State()) {
            SettingReducer()
        }

        await store.send(.onAppear)
    }

    @Test
    func defaultDisplayState() {
        let state = SettingReducer.State()

        #expect(state.appName == "MemoryBox")
        #expect(state.accountStatus.isEmpty == false)
        #expect(state.appVersion.isEmpty == false)
        #expect(state.buildNumber.isEmpty == false)
    }
}
