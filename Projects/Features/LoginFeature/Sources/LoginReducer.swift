//
//  LoginReducer.swift
//  LoginFeature
//
//  Created by 박지봉 on 4/22/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import ComposableArchitecture
import KakaoSDKUser
import AuthenticationServices
import AuthData
import AuthDomain
import Core

@Reducer
public struct LoginReducer {
    
    @Dependency(\.authRepository) var authRepository
    
    public init() {
        
    }
    
    @ObservableState
    public struct State: Equatable {
        public init() {
            
        }
        
        public var name: String?
        public var isPresented: Bool = false
        var loginError: String?
    }
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case loginButtonTapped(LoginType)
        case didSuccessLocalLogin(LoginVO)
        case didFailLocalLogin
        case didFinishServerLogin(DataResult<String>)
        case logout
        case loadUserData
    }
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
                
            case .loginButtonTapped(.kakao):
                
                return .none
                
            case .loginButtonTapped(.apple):
                return .none
                
            case .didSuccessLocalLogin(let vo):
                
                return authRepository.loginUser(vo)
                    .map { @Sendable ret in
                        
                        return .didFinishServerLogin(ret)
                    }
                
            case .didFailLocalLogin:
                return .none
                
            case .didFinishServerLogin(let result):
                state.isPresented = false
                
                if result.isSuccess {
                    state.name = result.data ?? ""
                }
                
                return .none

            case .binding:
                return .none
                
            case .logout:
                state.name = nil
                authRepository.logoutUser()
                return .none
                
            case .loadUserData:
                state.name = authRepository.userName
                return .none
                
            }
        }
    }
}
