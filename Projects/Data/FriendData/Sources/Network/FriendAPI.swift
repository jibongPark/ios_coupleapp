//
//  FriendAPI.swift
//  FriendData
//
//  Created by 박지봉 on 5/23/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Moya
import Foundation

enum FriendAPI {
    case friends
    case friendRequests
    case createInvite
    case request(uid: String)
    case acceptFriend(friendId: String)
    case deleteFriend(friendId: String)
}


extension FriendAPI: TargetType {
    var headers: [String : String]? {
        ["Content-Type": "application/json"]
    }
    
    var baseURL: URL {
        let url = Bundle.main.object(forInfoDictionaryKey:"BASE_URL")
        
        if let urlString = url as? String {
            return URL(string: urlString)!
        } else {
            fatalError("URL String not found")
        }
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
        }
    }
    
    var validationType: ValidationType {
        return .successCodes
    }
}
