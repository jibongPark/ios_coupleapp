//
//  FriendRepository.swift
//  FriendData
//
//  Created by 박지봉 on 5/23/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import FriendDomain
import CommonData
import ComposableArchitecture
import Moya
import Core

public final class FriendRepositoryImpl: FriendRepository {
    @Dependency(\.authInterceptor) var authInterceptor
    
    private lazy var session = Session(interceptor: authInterceptor)

    private lazy var provider = MoyaProvider<FriendAPI>(session: session)
    
    public func fetch() -> Effect<DataResult<[FriendVO]>> {
        
        let localProvider = provider
        
        return Effect.run { send in
            
            let result = await localProvider.request(.friends)
            
            let returnResult: DataResult<[FriendVO]> = DataResult(result, dtoType: [FriendDTO].self) { dtos in
                dtos.compactMap { FriendVO(id: $0.id, name: $0.name) }
            }
            
            await send(returnResult)
        }
    }
    
    public func friendRequest(_ uid: String) -> Effect<DataResult<FriendRequestVO>> {
        let localProvider = provider
        
        return Effect.run { send in
            let moyaResult = await localProvider.request(.request(uid: uid))
            
            let dataResult: DataResult<FriendRequestVO> = DataResult(moyaResult, dtoType: FriendRequestDTO.self) { dto in
                FriendRequestVO(senderId: dto.senderId,
                                senderName: dto.senderName,
                                receiverId: dto.receiverId,
                                receiverName: dto.receiverName)
            }
            
            await send(dataResult)
        }
    }
    
    public func acceptRequest(_ id: String) -> Effect<DataResult<FriendVO>> {
        let localProvider = provider
        
        return Effect.run { send in
            let moyaResult = await localProvider.request(.acceptFriend(friendId: id))
            
            let dataResult: DataResult<FriendVO> = DataResult(moyaResult, dtoType: FriendDTO.self) { dto in
                FriendVO(id: dto.id, name: dto.name)
            }
            
            await send(dataResult)
        }
    }
    
    public func declineRequest(_ id: String) -> Effect<DataResult<FriendVO>> {
        let localProvider = provider
        
        return Effect.run { send in
//            let moyaResult = await localProvider.request(.declineFriend(friendId: id))
//
//            let dataResult: DataResult<FriendVO> = DataResult(moyaResult, dtoType: FriendDTO.self) { dto in
//                FriendVO(id: dto.id, name: dto.name)
//            }
            
            let dataResult: DataResult<FriendVO> = DataResult(message: "")
            
            await send(dataResult)
        }
    }
    
    public func deleteFriend(_ id: String) -> Effect<DataResult<FriendVO>> {
        let localProvider = provider
        
        return Effect.run { send in
            let moyaResult = await localProvider.request(.deleteFriend(friendId: id))
            
            let dataResult: DataResult<FriendVO> = DataResult(moyaResult, dtoType: FriendDTO.self) { dto in
                FriendVO(id: dto.id, name: dto.name)
            }
            
            await send(dataResult)
        }
    }
}


private enum FriendRepoKey: DependencyKey {
    static var liveValue: FriendRepository = FriendRepositoryImpl()
}

public extension DependencyValues {
    var friendRepository: FriendRepository {
        get { self[FriendRepoKey.self] }
        set { self[FriendRepoKey.self] = newValue }
    }
}
