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
            
            switch result {
            case .success(let resp):
                do {
                    let apiResp: APIResponse<[FriendDTO]> = try resp.mapAPIResponse([FriendDTO].self)
                    let friends = apiResp.data?.compactMap { FriendVO(id: $0.id, name: $0.name)} ?? []
                    
                    await send(DataResult(friends))
                } catch {
                    
                }
            case .failure(let error): break
            }
        }
    }
    
    public func createRequest() -> Effect<DataResult<FriendInviteVO>> {
        let localProvider = provider
        
        return Effect.run { send in
            let result = await localProvider.request(.createInvite)
            
            switch result {
            case .success(let resp):
                do {
                    let apiResp: APIResponse<FriendInviteDTO> = try resp.mapAPIResponse(FriendInviteDTO.self)
                    let inviteDto = apiResp.data!
                    
                    await send(DataResult(FriendInviteVO(url: inviteDto.intiteUrl, expiresAt: inviteDto.expiresAt)))
                } catch {
                    await send(DataResult(nil, error: error))
                }
                
            case .failure(let error):
                await send(DataResult(nil, error: error))
            }
        }
    }
    
    public func friendRequest(_ token: String) -> Effect<DataResult<String>> {
        let localProvider = provider
        
        return Effect.run { send in
        let result = await localProvider.request(.request(token: token))
            
            switch result {
            case .success(let resp):
                do {
                    let apiResp: APIResponse<String> = try resp.mapAPIResponse(String.self)
                    let message = apiResp.data!
                    
                    await send(DataResult(apiResp.message))
                } catch {
                    
                }
                
            case .failure(let error):
                await send(DataResult(nil, error: error))
            }
        }
    }
    
    public func acceptRequest(_ id: String) {
        
    }
    
    public func declineRequest(_ id: String) {
        
    }
    
    public func deleteFriend(_ id: String) {
        
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
