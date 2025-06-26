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
        
        var friends: [FriendVO] = []
        var requests: [FriendRequestVO] = []
        
        var friendId: String = "6846a69a16ed8c3129b1d5e7"
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case alert(PresentationAction<Alert>)
        
        case fetchFriends
        case didFetchFriends([FriendVO])
        
        case didTapRequestButton(String)
        case didSuccessRequest(FriendRequestVO)
        
        case copyMyId
        
        case showAlert(String)
        case dismissAlert
        
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
                
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
