//
//  AuthRepository.swift
//  AuthDomain
//
//  Created by 박지봉 on 4/22/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//


import ComposableArchitecture
import Foundation
import Core

public protocol AuthRepository: Sendable {
    var userName: String? { get }
    
    func loginUser(_ user: LoginVO) -> Effect<DataResult<String>>
    func logoutUser()
}
