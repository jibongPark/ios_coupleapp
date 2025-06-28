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
@preconcurrency import Core


public final class AuthRepositoryImpl: AuthRepository, @unchecked Sendable {
    
    public init() {
        
    }
    
    @Dependency(\.authInterceptor) var authInterceptor
    
    private lazy var session = Session(interceptor: authInterceptor)

    
    @Dependency(\.authManager) var authManager
    
    private lazy var provider = MoyaProvider<AuthAPI>(session: session)
    
    public var userName: String? {
        get {
            authManager.userName
        }
    }
    
    public var accessToken: String? {
        get {
            authManager.accessToken
        }
    }
    
    public var refreshToken: String? {
        get {
            authManager.refreshToken
        }
    }
    
    public func loginUser(_ user: LoginVO) -> Effect<DataResult<String>> {
        
        return Effect.run { [self] send async in
            
            let result = await provider.request(.login(type: user.type, jwt: user.token, name: user.name))
            
            let returnResult: DataResult<String> = DataResult(result, dtoType: AuthVO.self) { dto in
                
                let userName = dto.userName
                let uid = dto.uid
                let accessToken = dto.accessToken
                let refreshToken = dto.refreshToken
                
                authManager.updateUserName(userName)
                authManager.updateUid(uid)
                authManager.updateToken(access: accessToken, refresh: refreshToken)
                
                ConfigManager.shared.set("userName", userName)
                ConfigManager.shared.set("uid", uid)
                ConfigManager.shared.set("didLogin", true)
                
                return dto.userName
            }
            
            await send(returnResult)
        }
    }
    
    public func updateUser(_ user: AuthDomain.UserVO) {
        
    }
    
    public func refreshToken(refreshToken: String) async -> AuthTokens? {
        let result: Result<Response, MoyaError> = await withCheckedContinuation { continuation in
            provider.request(.refresh(token: refreshToken)) { moyaResult in
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
                let response: APIResponse<AuthTokens> = try resp.mapAPIResponse(AuthTokens.self)
                
                if response.success {
                    
                    let accessToken = response.data!.accessToken
                    let refreshToken = response.data!.newRefreshToken
                    
                    authManager.updateToken(access: accessToken, refresh: refreshToken)
                    
                    return AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
                    
                } else {
                    
                }
            case .failure(let error):
                
                print(error)
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    public func logoutUser() {
        ConfigManager.shared.set("userName", "")
        ConfigManager.shared.set("didLogin", false)
        authManager.clear()
    }
    
    public func deleteUser() -> Effect<DataResult<String>> {
        
        return Effect.run { [self] send async in
            
            let result = await provider.request(.deleteUser)
            
            let returnResult: DataResult<String> = DataResult(result, dtoType: String.self) { dto in
                return dto
            }
            
            await send(returnResult)
        }
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
