import AuthDomain
import ComposableArchitecture
import Core
import Testing
@testable import LoginFeature

private struct TestAuthRepository: AuthRepository {
    var userName: String?
    var didLogout: @Sendable () -> Void = {}

    func loginUser(_ user: LoginVO) -> Effect<DataResult<String>> {
        .none
    }

    func logoutUser() {
        didLogout()
    }

    func deleteUser() -> Effect<DataResult<String>> {
        .none
    }
}

@MainActor
struct LoginReducerTests {
    @Test
    func logoutClearsName() async {
        let store = TestStore(initialState: LoginReducer.State()) {
            LoginReducer()
        } withDependencies: {
            $0.authRepository = TestAuthRepository(userName: "봉봉")
        }

        await store.send(.didFinishServerLogin(DataResult(isSuccess: true, data: "봉봉", message: ""))) { state in
            state.isPresented = false
            state.name = "봉봉"
        }
        await store.receive(\.delegate.didSuccessLogin)

        await store.send(.logout) { state in
            state.name = nil
        }
    }

    @Test
    func loadUserDataReadsStoredUserName() async {
        let store = TestStore(initialState: LoginReducer.State()) {
            LoginReducer()
        } withDependencies: {
            $0.authRepository = TestAuthRepository(userName: "봉봉")
        }

        await store.send(.loadUserData) { state in
            state.name = "봉봉"
        }
    }
}
