//
//  AuthVO.swift
//  AuthDomain
//
//  Created by 박지봉 on 4/22/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation

public enum LoginType: String, Equatable, Codable {
    case kakao
    case apple
}


public struct LoginVO: Equatable, Codable {
    public let type: LoginType
    public let name: String
    public let token: String
    
    public init(type: LoginType, name: String, token: String) {
        self.type = type
        self.name = name
        self.token = token
    }
}

public struct AuthVO: Equatable, Codable {
    public let userName: String
    public let uid: String
    public let accessToken: String
    public let refreshToken: String
    
    public init(name: String, uid: String, access: String, refresh: String) {
        self.userName = name
        self.uid = uid
        self.accessToken = access
        self.refreshToken = refresh
    }
}
