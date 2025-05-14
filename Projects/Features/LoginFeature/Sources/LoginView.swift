//
//  LoginView.swift
//  LoginFeature
//
//  Created by 박지봉 on 4/22/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//


import SwiftUI
import ComposableArchitecture
import LoginFeatureInterface
import _AuthenticationServices_SwiftUI
import AuthDomain

public struct LoginView: View {
    
    let store: StoreOf<LoginReducer>
    
    public init(store: StoreOf<LoginReducer>) {
        self.store = store
    }
    
    public var body: some View {
        VStack(alignment: .center) {
            Text("로그인 방법 선택")
//            Button(action: {
//                store.send(.loginButtonTapped(.kakao))
//            }, label: {
//                if let imageUrl = Bundle.module.url(forResource: "kakao_login", withExtension: "png"),
//                   let image = UIImage(contentsOfFile: imageUrl.path) {
//                    
//                    Image(uiImage: image)
//                        .resizable()
//                        .frame(width: 183, height: 45)
//                    
//                } else {
//                    Text("카카오 로그인")
//                }
//            })
            
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName]
                }, onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        switch authResults.credential {
                        case let appleIDCredential as ASAuthorizationAppleIDCredential:
                            let name = appleIDCredential.fullName?.givenName ?? ""
                            
                            if let IdentityToken = String(data: appleIDCredential.identityToken!, encoding: .utf8) {
                                store.send(.didSuccessLocalLogin(LoginVO(type: .apple, name: name, token: IdentityToken)))
                            }
                            
                        default:
                            break
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                        print("error")
                    }
                })
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(width: 183, height: 45)
        }
        .padding(15)
        .background(.white)
        .clipShape(.rect(cornerRadius:5))
        
    }
}


//public struct LoginFeature: LoginInterface {
//    
//    private var store: StoreOf<LoginReducer>
//    
//    public init() {
//        self.store = .init(initialState: LoginReducer.State()) {
//            LoginReducer()
//        }
//    }
//    
//    public func makeView() -> any View {
//        AnyView(
//            LoginView(store: self.store)
//        )
//    }
//    
//    public mutating func setPresented(_ presendted: Binding<Bool>) {
//        store.isPresented = presendted
//    }
//}
//
//enum LoginFeatureKey: DependencyKey {
//    static var liveValue: LoginInterface = LoginFeature()
//}
//
//public extension DependencyValues {
//    var loginFeature: LoginInterface {
//        get { self[LoginFeatureKey.self] }
//        set { self[LoginFeatureKey.self] = newValue }
//    }
//}
