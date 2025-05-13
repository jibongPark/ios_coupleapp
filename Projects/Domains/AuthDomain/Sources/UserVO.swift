//
//  UserVO.swift
//  AuthDomain
//
//  Created by 박지봉 on 4/22/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation

public struct UserVO: Equatable, Codable {
    public let type: String
    public let name: String
    public let id: String
    
    public init(type: String, name: String, num: Int = -1, id: String) {
        self.type = type
        self.name = name
        self.id = id
    }
}
