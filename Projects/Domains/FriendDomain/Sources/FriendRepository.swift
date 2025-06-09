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
    func createRequest() -> Effect<DataResult<FriendInviteVO>>
    func friendRequest(_ token: String) -> Effect<DataResult<String>>
    func acceptRequest(_ id: String)
    func declineRequest(_ id: String)
    func deleteFriend(_ id: String)
}
