//
//  AuthTokens.swift
//  CommonData
//
//  Created by 박지봉 on 5/14/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

public struct AuthTokens: Decodable {
    
    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.newRefreshToken = refreshToken
    }
    
    public let accessToken: String
    public let newRefreshToken: String
}
