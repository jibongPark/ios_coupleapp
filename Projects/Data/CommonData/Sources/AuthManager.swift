//
//  AuthManager.swift
//  Core
//
//  Created by 박지봉 on 5/13/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Dependencies
import Core

public final class AuthManager {
    
    var keyChainHelper = KeychainHelper.standard
    
    private let tag = "com.bongbong.auth.login".data(using: .utf8)!
    private let userService = "com.bongbong.userinfo"
    private let nameAccount = "userName"
    private let accessAccount = "accessToken"
    private let refreshAccount = "refreshToken"
    
    public static let shared = AuthManager()
    
    public private(set) var userName: String?
    public private(set) var accessToken: String?
    public private(set) var refreshToken: String?
    
    private init() {
        do {
            let name = try keyChainHelper.read(service: userService, account: nameAccount)
            if let name = name {
                userName = name
            }
            
            let accessToken = try keyChainHelper.read(service: userService, account: accessAccount)
            if let accessToken = accessToken {
                self.accessToken = accessToken
            }
            
            let refreshToken = try keyChainHelper.read(service: userService, account: refreshAccount)
            if let refreshToken = refreshToken {
                self.refreshToken = refreshToken
            }
            
        } catch {
            print("🔑 AuthManager 초기 로드 실패:", error)
        }
    }
    
    public func updateUserName(_ name: String) {
        self.userName = name
        
        do {
            try KeychainHelper.standard.save(name, service: userService, account: nameAccount)
        } catch {
            
        }
    }
    
    public func updateToken(access: String, refresh: String) {
        self.accessToken = access
        self.refreshToken = refresh
        
        do {
            try KeychainHelper.standard.save(access, service: userService, account: accessAccount)
            try KeychainHelper.standard.save(refresh, service: userService, account: refreshAccount)
        } catch {
            
        }
    }
    
    public func clear() {
        userName = nil
        accessToken = nil
        refreshToken = nil
        
        KeychainHelper.standard.delete(service: userService, account: nameAccount)
        KeychainHelper.standard.delete(service: userService, account: accessAccount)
        KeychainHelper.standard.delete(service: userService, account: refreshAccount)
    }
}

private enum AuthManagerKey: DependencyKey {
    static var liveValue = AuthManager.shared
}

public extension DependencyValues {
    var authManager: AuthManager {
        get { self[AuthManagerKey.self] }
        set { self[AuthManagerKey.self] = newValue }
    }
}
