//
//  App.swift
//  coupleapp
//
//  Created by 박지봉 on 3/20/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct MyApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    private let store: StoreOf<AppReducer>
    
    init() {
        store = .init(initialState: AppReducer.State()) {
            AppReducer()
        }
        
        if let kakaoKey = Bundle.main.object(forInfoDictionaryKey:"KAKAO_APP_KEY") as? String {
            KakaoSDK.initSDK(appKey: kakaoKey)
        } else {
            print("카카오 키 없음")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(store: store)
                .onOpenURL(perform: { url in
                    if (AuthApi.isKakaoTalkLoginUrl(url)) {
                        AuthController.handleOpenUrl(url: url)
                    }
                })
        }
    }
}
