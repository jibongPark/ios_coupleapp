//
//  FriendDTO.swift
//  FriendData
//
//  Created by 박지봉 on 5/23/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation


struct FriendDTO: Codable {
    var id: String
    var name: String
}

struct FriendInviteDTO: Codable {
    var intiteUrl: String
    var expiresAt: Date
}
