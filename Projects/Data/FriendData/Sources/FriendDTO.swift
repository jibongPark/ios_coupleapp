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

struct FriendRequestDTO: Codable {
    var senderId: String
    var senderName: String
    var receiverId: String
    var receiverName: String
}

struct FriendInviteDTO: Codable {
    var intiteUrl: String
    var expiresAt: Date
}

struct SharedSpaceDTO: Codable {
    var id: String
    var type: String
    var name: String?
    var members: [SharedSpaceMemberDTO]
    var createdAt: Date?
    var updatedAt: Date?
}

struct SharedSpaceMemberDTO: Codable {
    var userId: String
    var name: String
    var role: String
}

struct PairingInviteDTO: Codable {
    var code: String
    var sharedSpaceId: String?
    var inviterId: String
    var expiresAt: Date?
}
