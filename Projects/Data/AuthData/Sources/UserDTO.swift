//
//  UserDTO.swift
//  AuthData
//
//  Created by 박지봉 on 4/23/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import AuthDomain

public struct UserDTO: Codable, Equatable {
    public let type: String
    public let name: String
    public let num: Int
    public let id: String
    
    public init(type: String, name: String, num: Int, id: String) {
        self.type = type
        self.name = name
        self.num = num
        self.id = id
    }
}

public extension UserDTO {
    func toVO() -> UserVO {
        UserVO(type: self.type, name: self.name, num: self.num, id: self.id)
    }
}

public extension UserVO {
    func toDTO() -> UserDTO {
        UserDTO(
            type: self.type,
            name: self.name,
            num: 1,
            id: self.id)
    }
}
