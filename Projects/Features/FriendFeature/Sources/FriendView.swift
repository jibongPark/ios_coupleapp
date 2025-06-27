//
//  FriendView.swift
//  FriendFeature
//
//  Created by 박지봉 on 6/4/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import ComposableArchitecture
import FriendFeatureInterface
import SwiftUI
import Core
import FriendDomain



struct FriendView: View {
    
    @Bindable var store: StoreOf<FriendReducer>
    
    init(store: StoreOf<FriendReducer>) {
        self.store = store
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                VStack {
                    
                    HStack(spacing: 0) {
                        
                        Text("uid : ")
                        
                        ImageButton("document.on.document.fill") {
                            store.send(.copyMyId)
                        }
                        .frame(width: 24, height: 24)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .contentShape(Rectangle())
                        
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 0) {
                        TextField(text: $store.friendId, label: {
                            Text("초대코드를 입력해주세요.")
                        })
                        
                        Spacer(minLength: 0)
                        
                        Button(action: {
                            store.send(.didTapRequestButton(store.friendId))
                        }, label: {
                            Image(systemName: "person.fill.badge.plus")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(Color.mbPrimaryRose)
                                .frame(width: 24, height: 24)
                                .padding(10)
                        })
                        .frame(alignment: .trailing)
                        .contentShape(Rectangle())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    
                    LazyVStack {
                        
                        ForEach(store.requests.indices, id: \.self) { index in
                            let request = store.requests[index]
                            FriendRequestView(store: store, isMyRequest: request.senderId == store.userId, friendRequest: request)
                        }
                        
                        ForEach(store.friends.indices, id: \.self) { index in
                            FriendCellView(store: store, friend: store.friends[index])
                        }
                    }
                }
                .padding([.leading, .trailing], 10)
            }
            .alert($store.scope(state: \.alert, action: \.alert))
            .background(Color.mbBackgroundBeige)
            .toolbar {
                
                ToolbarItem(placement: .principal) {
                    Text("친구")
                        .foregroundStyle(Color.mbTextBlack)
                }
            }
            
        }
        .onAppear() {
            store.send(.onAppear)
        }
    }
    
    private struct FriendRequestView: View {
        var store: StoreOf<FriendReducer>
        let isMyRequest: Bool
        let friendRequest: FriendRequestVO
        
        var body: some View {
            
            GeometryReader { geometry in
                HStack {
                    if isMyRequest {
                        Text(friendRequest.receiverName)
                        
                        Spacer()
                        
                        HStack {
                            Button(action: {
                                store.send(.deleteFriend(friendRequest.receiverId))
                            }, label: {
                                Image(systemName: "x.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(Color.mbPrimaryTerracotta)
                                    .frame(width: 24, height: 24)
                                    .padding(10)
                            })
                        }
                    } else {
                        Text(friendRequest.senderName)
                            .background(Color.mbInputBackground)
                        
                        Spacer()
                        
                        
                        ImageButton("o.circle.fill") {
                            store.send(.acceptFriend(friendRequest.senderId))
                        }
                        .frame(width: 24, height: 24)
                        .padding(10)
                        Button(action: {
                            store.send(.acceptFriend(friendRequest.senderId))
                        }, label: {
                            Image(systemName: "o.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(Color.mbPrimaryTerracotta)
                                .frame(width: 24, height: 24)
                                .padding(10)
                        })
                        
                        Button(action: {
                            store.send(.rejectFriend(friendRequest.senderId))
                        }, label: {
                            Image(systemName: "x.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(Color.mbPrimaryTerracotta)
                                .frame(width: 24, height: 24)
                                .padding(10)
                        })
                        
                    }
                    
                }
                .padding(5)
            }
        }
    }
    
    private struct FriendCellView: View {
        var store: StoreOf<FriendReducer>
        let friend: FriendVO
        
        var body: some View {
            HStack {
                Text(friend.name)
                    .background(Color.mbInputBackground)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(5)
        }
    }
}

#Preview {
    FriendView(store: .init(initialState: FriendReducer.State(), reducer: {
        FriendReducer()
    }))
}

public struct FriendFeature: FriendInterface {
    
    private let store: StoreOf<FriendReducer>
    
    public init() {
        self.store = .init(initialState: FriendReducer.State()) {
            FriendReducer()
        }
    }
    
    public func makeView() -> any View {
        AnyView(
            FriendView(store: self.store)
        )
    }
}


enum FriendFeatureKey: DependencyKey {
    static var liveValue: FriendInterface = FriendFeature()
}

public extension DependencyValues {
    var friendFeature: FriendInterface {
        get { self[FriendFeatureKey.self] }
        set { self[FriendFeatureKey.self] = newValue }
    }
}
