//
//  AuthError.swift
//  AuthData
//
//  Created by 박지봉 on 5/9/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

public enum AuthError: Error, Equatable {
    case networkFailed
    case invalidCredential
    case tokenMissing
    case accessExpired
    case refreshExpired
    case unknown
}
