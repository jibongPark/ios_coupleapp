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

    private func unavailableBaseURLResult<T>() -> Effect<DataResult<T>> {
        Effect.run { send in
            await send(DataResult(message: ConfigManager.missingAPIBaseURLMessage))
        }
    }

    private func mapSharedSpace(_ dto: SharedSpaceDTO) -> SharedSpaceVO {
        SharedSpaceVO(
            id: dto.id,
            type: SharedSpaceType(rawValue: dto.type) ?? .pair,
            name: dto.name,
            members: dto.members.map { member in
                SharedSpaceMemberVO(
                    userId: member.userId,
                    name: member.name,
                    role: SharedSpaceMemberRole(rawValue: member.role) ?? .member
                )
            },
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    private func mapPairingInvite(_ dto: PairingInviteDTO) -> PairingInviteVO {
        PairingInviteVO(
            code: dto.code,
            sharedSpaceId: dto.sharedSpaceId,
            inviterId: dto.inviterId,
            expiresAt: dto.expiresAt
        )
    }
    
    public func fetch() -> Effect<DataResult<[FriendVO]>> {
        guard ConfigManager.shared.hasValidAPIBaseURL else {
            return unavailableBaseURLResult()
        }
        
        let localProvider = provider
        
        return Effect.run { send in
            
            let result = await localProvider.request(.friends)
            
            let returnResult: DataResult<[FriendVO]> = DataResult(result, dtoType: [FriendDTO].self) { dtos in
                dtos.compactMap { FriendVO(id: $0.id, name: $0.name) }
            }
            
            await send(returnResult)
        }
    }
    
    public func fetchRequests() -> Effect<DataResult<[FriendRequestVO]>> {
        guard ConfigManager.shared.hasValidAPIBaseURL else {
            return unavailableBaseURLResult()
        }

        let localProvider = provider
        
        return Effect.run { send in
            
            let result = await localProvider.request(.friendRequests)
            
            let returnResult: DataResult<[FriendRequestVO]> = DataResult(result, dtoType: [FriendRequestDTO].self) { dtos in
                dtos.compactMap { FriendRequestVO(senderId: $0.senderId, senderName: $0.senderName, receiverId: $0.receiverId, receiverName: $0.receiverName) }
            }
            
            await send(returnResult)
        }
    }
    
    public func friendRequest(_ uid: String) -> Effect<DataResult<FriendRequestVO>> {
        guard ConfigManager.shared.hasValidAPIBaseURL else {
            return unavailableBaseURLResult()
        }

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
    
    public func acceptFriend(_ id: String) -> Effect<DataResult<FriendVO>> {
        guard ConfigManager.shared.hasValidAPIBaseURL else {
            return unavailableBaseURLResult()
        }

        let localProvider = provider
        
        return Effect.run { send in
            let moyaResult = await localProvider.request(.acceptFriend(friendId: id))
            
            let dataResult: DataResult<FriendVO> = DataResult(moyaResult, dtoType: FriendDTO.self) { dto in
                FriendVO(id: dto.id, name: dto.name)
            }
            
            await send(dataResult)
        }
    }
    
    public func rejectFriend(_ id: String) -> Effect<DataResult<FriendVO>> {
        guard ConfigManager.shared.hasValidAPIBaseURL else {
            return unavailableBaseURLResult()
        }

        let localProvider = provider
        
        return Effect.run { send in
            let moyaResult = await localProvider.request(.deleteFriend(friendId: id))

            let dataResult: DataResult<FriendVO> = DataResult(moyaResult, dtoType: FriendDTO.self) { dto in
                FriendVO(id: dto.id, name: dto.name)
            }
            
            await send(dataResult)
        }
    }
    
    public func deleteFriend(_ id: String) -> Effect<DataResult<FriendVO>> {
        guard ConfigManager.shared.hasValidAPIBaseURL else {
            return unavailableBaseURLResult()
        }

        let localProvider = provider
        
        return Effect.run { send in
            let moyaResult = await localProvider.request(.deleteFriend(friendId: id))
            
            let dataResult: DataResult<FriendVO> = DataResult(moyaResult, dtoType: FriendDTO.self) { dto in
                FriendVO(id: dto.id, name: dto.name)
            }
            
            await send(dataResult)
        }
    }

    public func fetchActiveSharedSpace() -> Effect<DataResult<SharedSpaceVO?>> {
        guard ConfigManager.shared.hasValidAPIBaseURL else {
            return unavailableBaseURLResult()
        }

        let localProvider = provider
        let mapSharedSpace = self.mapSharedSpace

        return Effect.run { send in
            let moyaResult = await localProvider.request(.activeSharedSpace)

            let dataResult: DataResult<SharedSpaceVO?> = DataResult(moyaResult, dtoType: SharedSpaceDTO?.self) { dto in
                dto.map(mapSharedSpace)
            }

            if let sharedSpace = dataResult.data ?? nil {
                ConfigManager.shared.set("activeSharedSpaceId", sharedSpace.id)
            }

            await send(dataResult)
        }
    }

    public func createPairingInvite() -> Effect<DataResult<PairingInviteVO>> {
        guard ConfigManager.shared.hasValidAPIBaseURL else {
            return unavailableBaseURLResult()
        }

        let localProvider = provider
        let mapPairingInvite = self.mapPairingInvite

        return Effect.run { send in
            let moyaResult = await localProvider.request(.createPairingInvite)

            let dataResult: DataResult<PairingInviteVO> = DataResult(moyaResult, dtoType: PairingInviteDTO.self) { dto in
                mapPairingInvite(dto)
            }

            await send(dataResult)
        }
    }

    public func acceptPairingInvite(_ code: String) -> Effect<DataResult<SharedSpaceVO>> {
        guard ConfigManager.shared.hasValidAPIBaseURL else {
            return unavailableBaseURLResult()
        }

        let localProvider = provider
        let mapSharedSpace = self.mapSharedSpace

        return Effect.run { send in
            let moyaResult = await localProvider.request(.acceptPairingInvite(code: code))

            let dataResult: DataResult<SharedSpaceVO> = DataResult(moyaResult, dtoType: SharedSpaceDTO.self) { dto in
                mapSharedSpace(dto)
            }

            if let sharedSpace = dataResult.data {
                ConfigManager.shared.set("activeSharedSpaceId", sharedSpace.id)
            }

            await send(dataResult)
        }
    }

    public func leaveSharedSpace(_ id: String) -> Effect<DataResult<SharedSpaceVO>> {
        guard ConfigManager.shared.hasValidAPIBaseURL else {
            return unavailableBaseURLResult()
        }

        let localProvider = provider
        let mapSharedSpace = self.mapSharedSpace

        return Effect.run { send in
            let moyaResult = await localProvider.request(.leaveSharedSpace(id: id))

            let dataResult: DataResult<SharedSpaceVO> = DataResult(moyaResult, dtoType: SharedSpaceDTO.self) { dto in
                mapSharedSpace(dto)
            }

            if dataResult.isSuccess {
                ConfigManager.shared.set("activeSharedSpaceId", "")
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
