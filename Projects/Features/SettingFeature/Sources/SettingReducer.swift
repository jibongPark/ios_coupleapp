import ComposableArchitecture
import Foundation

@Reducer
struct SettingReducer {
    @ObservableState
    struct State: Equatable {
        var appName: String = "MemoryBox"
        var accountStatus: String = "로그인 상태는 사이드 메뉴에서 확인할 수 있습니다."
        var appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        var buildNumber: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
    }

    enum Action: Equatable {
        case onAppear
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .onAppear:
                return .none
            }
        }
    }
}
