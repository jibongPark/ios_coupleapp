//
//  LoginResponse.swift
//  AuthData
//
//  Created by 박지봉 on 5/8/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

struct AuthResponse: Decodable {
    let accessTokken: String
    let refreshTokken: String
}
