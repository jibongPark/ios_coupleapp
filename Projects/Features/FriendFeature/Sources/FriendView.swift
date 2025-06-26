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
                        Button(action: {
                            store.send(.copyMyId)
                        }, label: {
                            Image(systemName: "document.on.document.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(Color.mbPrimaryTerracotta)
                                .frame(width: 24, height: 24)
                                .padding(10)
                        })
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
                        ForEach(store.friends.indices, id: \.self) { index in
                            Text(store.friends[index].name)
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
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        
                    }, label: {
                        Image(systemName: "arrow.backward")
                            .foregroundStyle(Color.mbBackwardColor)
                    })
                }
            }
            
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
