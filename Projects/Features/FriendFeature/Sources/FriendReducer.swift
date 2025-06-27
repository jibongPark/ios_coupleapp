//
//  FriendReducer.swift
//  FriendFeature
//
//  Created by 박지봉 on 6/4/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import ComposableArchitecture
import FriendData
import FriendDomain

import UIKit

@Reducer
struct FriendReducer {
    
    @Dependency(\.friendRepository) var friendRepository
    @Dependency(\.authManager) var authManager
    
    init() {
        
    }
    
    @ObservableState
    public struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        
        var userId: String = ""
        
        var friends: [FriendVO] = []
        var requests: [FriendRequestVO] = []
        
        var friendId: String = ""
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case alert(PresentationAction<Alert>)
        
        case fetchFriends
        case didFetchFriends([FriendVO])
        
        case fetchFriendRequests
        case didFetchFriendRequests([FriendRequestVO])
        
        case didTapRequestButton(String)
        case didSuccessRequest(FriendRequestVO)
        
        case deleteFriend(String)
        case didDeleteFriend(FriendVO)
        case acceptFriend(String)
        case didAcceptFriend(FriendVO)
        case rejectFriend(String)
        case didRejectFriend(FriendVO)
        
        case copyMyId
        
        case showAlert(String)
        case dismissAlert
        
        case onAppear
        
        @CasePathable
        enum Alert: Equatable {
            case dismiss
        }
        
    }
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            
            switch action {
                
            case .binding:
                return .none
                
            case .alert(.presented(.dismiss)):
                state.alert = nil
                return .none
                
            case .alert:
                return .none
            
                
            case .fetchFriends:
                return friendRepository.fetch().map { @Sendable resp in
                    if resp.isSuccess {
                        return .didFetchFriends(resp.data!)
                    }
                    return .showAlert(resp.message)
                }
                
            case .didFetchFriends(let friends):
                state.friends = friends
                return .none
                
            case .fetchFriendRequests:
                return friendRepository.fetchRequests().map { @Sendable resp in
                    if resp.isSuccess {
                        return .didFetchFriendRequests(resp.data!)
                    }
                    return .showAlert(resp.message)
                }
                
            case .didFetchFriendRequests(let requests):
                state.requests = requests
                return .none
                
            case .didTapRequestButton(let friendId):
                
                if !state.friendId.isEmpty {
                    return friendRepository.friendRequest(friendId).map { @Sendable resp in
                        if resp.isSuccess {
                            return .didSuccessRequest(resp.data!)
                        }
                        return .showAlert(resp.message)
                    }
                }
                
                return .none
                
            case .didSuccessRequest(let vo):
                state.requests.append(vo)
                return .send(.showAlert("친구 신청이 완료되었습니다."))
                
            case .deleteFriend(let id):
                return friendRepository.deleteFriend(id).map { @Sendable resp in
                    if resp.isSuccess {
                        if let friend = resp.data {
                            return .didDeleteFriend(friend)
                        }
                    }
                    
                    return .showAlert(resp.message)
                }
                
            case .didDeleteFriend(let friend):
                state.friends = state.friends.filter { $0.id != friend.id }
                state.requests = state.requests.filter { $0.senderId != friend.id && $0.receiverId != friend.id }
                return .none
                
            case .acceptFriend(let id):
                return friendRepository.acceptFriend(id).map { @Sendable resp in
                    if resp.isSuccess {
                        if let friend = resp.data {
                            return .didAcceptFriend(friend)
                        }
                    }
                    return .showAlert(resp.message)
                }
                
            case .didAcceptFriend(let friend):
                state.requests = state.requests.filter { $0.senderId != friend.id }
                state.friends.append(friend)
                return .none
                
            case .rejectFriend(let id):
                return friendRepository.rejectFriend(id).map { @Sendable resp in
                    if resp.isSuccess {
                        if let friend = resp.data {
                            return .didRejectFriend(friend)
                        }
                    }
                    return .showAlert(resp.message)
                }
                
            case .didRejectFriend(let friend):
                state.requests = state.requests.filter { $0.senderId != friend.id }
                return .none
            case .copyMyId:
                UIPasteboard.general.string = authManager.uid
                return .send(.showAlert("id가 복사되었습니다."))
                
            case .showAlert(let message):
                
                state.alert = AlertState {
                    TextState(message)
                } actions: {
                    ButtonState(action: .dismiss, label: {
                        TextState("확인")
                    })
                }
                
                return .none
                
            case .dismissAlert:
                state.alert = nil
                return .none
                
            case .onAppear:
                state.userId = authManager.uid ?? ""
                
                return .merge([
                    .send(.fetchFriends),
                    .send(.fetchFriendRequests)
                ])
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
