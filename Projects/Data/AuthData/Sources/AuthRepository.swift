//
//  AuthRepository.swift
//  AuthData
//
//  Created by 박지봉 on 4/23/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import CommonData
import AuthDomain
import CoreFoundation
import Security

import ComposableArchitecture
@preconcurrency import Moya
import Core


public struct AuthRepositoryImpl: AuthRepository {
    
    @Dependency(\.authManager) var authManager
    
    private let provider = MoyaProvider<AuthService>()
    
    private let tag = "com.bongbong.auth.login".data(using: .utf8)!
    private let userService = "com.bongbong.userinfo"
    private let nameAccount = "userName"
    private let accessAccount = "accessToken"
    private let refreshAccount = "refreshToken"
    
    public func getUserName() -> String? {
        authManager.userName
    }
    
    public func loginUser(_ user: LoginVO) -> Effect<DataResult<String>> {
        
        return Effect.run { send async in
            
            let result: Result<Response, MoyaError> = await withCheckedContinuation { continuation in
                provider.request(.login(type: user.type, jwt: user.token, name: user.name)) { moyaResult in
                    switch moyaResult {
                    case .success(let response):
                        continuation.resume(returning: .success(response))
                    case .failure(let moyaError):
                        continuation.resume(returning: .failure(moyaError))
                    }
                }
            }
            
            do {
                switch result {
                case .success(let resp):
                    let response: APIResponse<AuthVO> = try resp.mapAPIResponse(AuthVO.self)
                    
                    if response.success {
                        
                        let userName = response.data!.userName
                        let accessToken = response.data!.accessToken
                        let refreshToken = response.data!.refreshToken
                        
                        
                        authManager.updateUserName(userName)
                        authManager.updateToken(access: accessToken, refresh: refreshToken)
                        
                        await send(DataResult(userName))
                        
                    } else {
                        
                    }
                case .failure(let error):
                    await send(DataResult(error: AuthError.networkFailed))
                    print(error)
                }
            } catch {
                print(error)
            }
        }
    }
    
    public func updateUser(_ user: AuthDomain.UserVO) {
        
    }
    
    public func logoutUser() {
        authManager.clear()
    }
    
}

private enum AuthRepoKey: DependencyKey {
    static var liveValue: AuthRepository = AuthRepositoryImpl()
    static var testValue: AuthRepository = AuthRepositoryImpl()
}

public extension DependencyValues {
    var authRepository: AuthRepository {
        get { self[AuthRepoKey.self] }
        set { self[AuthRepoKey.self] = newValue }
    }
}
