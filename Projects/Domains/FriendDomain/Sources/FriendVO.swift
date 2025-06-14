//
//  FriendVO.swift
//  FriendDomain
//
//  Created by 박지봉 on 5/23/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation

public struct FriendVO: Equatable {
    public let id: String
    public let name: String
    
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct FriendInviteVO: Equatable {
    public let url: String
    public let expiresAt: Date
    
    public init(url: String, expiresAt: Date) {
        self.url = url
        self.expiresAt = expiresAt
    }
}
