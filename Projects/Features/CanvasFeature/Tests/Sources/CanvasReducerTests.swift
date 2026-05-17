import XCTest
import ComposableArchitecture
@testable import CanvasFeature
import CanvasDomain
import Core

@MainActor
final class CanvasReducerTests: XCTestCase {
    func testOnAppearWithoutSharedSpaceShowsPairingMessage() async {
        let store = TestStore(initialState: CanvasReducer.State(activeSharedSpaceId: nil)) {
            CanvasReducer()
        }

        await store.send(.onAppear) {
            $0.errorMessage = "페어링 후 우리 낙서장을 사용할 수 있어요."
        }
    }
}
