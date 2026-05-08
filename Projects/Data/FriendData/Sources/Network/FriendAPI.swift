//
//  FriendAPI.swift
//  FriendData
//
//  Created by 박지봉 on 5/23/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Moya
import Foundation
import Core

enum FriendAPI {
    case friends
    case friendRequests
    case createInvite
    case request(uid: String)
    case acceptFriend(friendId: String)
    case deleteFriend(friendId: String)
    case activeSharedSpace
    case createPairingInvite
    case acceptPairingInvite(code: String)
    case leaveSharedSpace(id: String)
}


extension FriendAPI: TargetType {
    var headers: [String : String]? {
        ["Content-Type": "application/json"]
    }
    
    var baseURL: URL {
        ConfigManager.shared.apiBaseURL ?? ConfigManager.fallbackBaseURL
    }
    
    var path: String {
        switch self {
        case .friends:
            return "/friends"
        case .friendRequests:
            return "/friendRequests"
        case .createInvite:
            return "/friend/createInvite"
        case .request(uid: let token):
            return "/friend/request/\(token)"
        case .acceptFriend(friendId: let friendId):
            return "/friend/accept/\(friendId)"
        case .deleteFriend(friendId: let friendId):
            return "/friend/\(friendId)"
        case .activeSharedSpace:
            return "/shared-spaces/active"
        case .createPairingInvite:
            return "/shared-spaces/invites"
        case .acceptPairingInvite(code: let code):
            return "/shared-spaces/invites/\(code)/accept"
        case .leaveSharedSpace(id: let id):
            return "/shared-spaces/\(id)/members/me"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .friends:
            return .get
        case .friendRequests:
            return .get
        case .createInvite:
            return .post
        case .request(uid: _):
            return .post
        case .acceptFriend(friendId: _):
            return .post
        case .deleteFriend(friendId: _):
            return .delete
        case .activeSharedSpace:
            return .get
        case .createPairingInvite:
            return .post
        case .acceptPairingInvite(code: _):
            return .post
        case .leaveSharedSpace(id: _):
            return .delete
        }
    }
    
    var task: Task {
        switch self {
        case .friends:
            return .requestPlain
        case .friendRequests:
            return .requestPlain
        case .createInvite:
            return .requestPlain
        case .request:
            return .requestPlain
        case .acceptFriend:
            return .requestPlain
        case .deleteFriend:
            return .requestPlain
        case .activeSharedSpace:
            return .requestPlain
        case .createPairingInvite:
            return .requestPlain
        case .acceptPairingInvite:
            return .requestPlain
        case .leaveSharedSpace:
            return .requestPlain
        }
    }
    
    var validationType: ValidationType {
        return .successCodes
    }
}
