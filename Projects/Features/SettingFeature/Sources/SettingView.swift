import ComposableArchitecture
import Core
import SettingFeatureInterface
import SwiftUI

struct SettingView: View {
    @Bindable var store: StoreOf<SettingReducer>

    var body: some View {
        NavigationStack {
            List {
                Section("앱 정보") {
                    HStack {
                        Text("앱 이름")
                        Spacer()
                        Text(store.appName)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("계정") {
                    Text(store.accountStatus)
                        .foregroundStyle(Color.mbTextBlack)
                }

                Section("빌드 정보") {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text(store.appVersion)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("빌드")
                        Spacer()
                        Text(store.buildNumber)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.mbBackgroundBeige)
            .navigationTitle("설정")
            .onAppear {
                store.send(.onAppear)
            }
        }
        .setBackgroundColor()
    }
}

public struct SettingFeature: SettingInterface {
    private let store: StoreOf<SettingReducer>

    public init() {
        store = .init(initialState: SettingReducer.State()) {
            SettingReducer()
        }
    }

    public func makeView() -> any View {
        AnyView(
            SettingView(store: self.store)
        )
    }
}

private enum SettingFeatureKey: DependencyKey {
    static var liveValue: SettingInterface = SettingFeature()
}

public extension DependencyValues {
    var settingFeature: SettingInterface {
        get { self[SettingFeatureKey.self] }
        set { self[SettingFeatureKey.self] = newValue }
    }
}
