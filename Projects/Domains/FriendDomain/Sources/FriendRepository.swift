//
//  FriendRepository.swift
//  FriendDomain
//
//  Created by 박지봉 on 5/23/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import ComposableArchitecture
import Core

public protocol FriendRepository {
    func fetch() -> Effect<DataResult<[FriendVO]>>
    func fetchRequests() -> Effect<DataResult<[FriendRequestVO]>>
    
    func friendRequest(_ uid: String) -> Effect<DataResult<FriendRequestVO>>
    func acceptFriend(_ id: String) -> Effect<DataResult<FriendVO>>
    func rejectFriend(_ id: String) -> Effect<DataResult<FriendVO>>
    func deleteFriend(_ id: String) -> Effect<DataResult<FriendVO>>
}
