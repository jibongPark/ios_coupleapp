import SwiftUI
import KakaoSDKAuth
import ComposableArchitecture
import LoginFeature
import KakaoSDKCommon

@main
struct LoginDemoApp: App {
    
    @Dependency(\.loginFeature) var loginFeature
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        if let kakaoKey = Bundle.main
            .object(forInfoDictionaryKey:"KAKAO_APP_KEY") as? String {
            KakaoSDK.initSDK(appKey: kakaoKey)
        } else {
            print("카카오 키 없음")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AnyView(loginFeature.makeView()).onOpenURL(perform: { url in
                if (AuthApi.isKakaoTalkLoginUrl(url)) {
                    AuthController.handleOpenUrl(url: url)
                }
            })
        }
    }
}
