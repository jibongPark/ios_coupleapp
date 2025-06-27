//
//  TestProject.swift
//  TestProject
//
//  Created by Junyoung on 1/8/25.
//

import SwiftUI
import ComposableArchitecture
import MapFeature
import CalendarFeature
import WidgetFeature
import LoginFeature
import FriendFeature

struct AppView: View {
    
    @Dependency(\.mapFeature) var mapFeature
    @Dependency(\.calendarFeature) var calendarFeature
    @Dependency(\.widgetFeature) var widgetFeature
    @Dependency(\.friendFeature) var friendFeature
    
    let store: StoreOf<AppReducer>
    
    @State var sideBarWidth: CGFloat = 0
    @State var lastDragValue: CGFloat = 0
    
    let sideBarMaxWidth: CGFloat = 300
    
    var body: some View {
        
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            
            NavigationStack {
                ZStack(alignment: .leading) {
                    
                    TabView {
                        
                        AnyView(mapFeature.makeView())
                            .tabItem {
                                Image(systemName: "map")
                                Text("여행지도")
                            }
                        AnyView(calendarFeature.makeView())
                            .tabItem {
                                Image(systemName: "calendar")
                                Text("캘린더")
                            }
                    }
                    .onAppear() {
                        UITabBar.appearance().scrollEdgeAppearance = .init()
                    }
                    
                    Button(action: {
                        withAnimation {
                            sideBarWidth = sideBarWidth == 0 ? sideBarMaxWidth : 0
                        }
                    }, label: {
                        Image(systemName: "line.horizontal.3")
                            .imageScale(.large)
                            .padding(10)
                            .contentShape(Rectangle())
                            .foregroundStyle(.black)
                    })
                    .frame(maxWidth:.infinity, maxHeight: .infinity, alignment: .topLeading)
                    
                    if sideBarWidth > 0 {
                        Rectangle()
                            .fill(.gray.opacity(0.3))
                            .onTapGesture {
                                withAnimation {
                                    sideBarWidth = 0
                                }
                            }
                    }
                    
                    sideBarMenu(store: store)
                        .frame(width: sideBarMaxWidth)
                        .offset(x: sideBarWidth - sideBarMaxWidth)
                        .gesture (
                            DragGesture(minimumDistance: 30)
                                .onChanged() { gesture in
                                    let delta = gesture.translation.width - lastDragValue
                                    lastDragValue = gesture.translation.width
                                    
                                    let newWidth = sideBarWidth + delta
                                    sideBarWidth = min(max(newWidth, 0), 300)
                                }
                                .onEnded() { _ in
                                    
                                    withAnimation {
                                        if sideBarWidth >= (sideBarMaxWidth/2) {
                                            sideBarWidth = sideBarMaxWidth
                                        } else {
                                            sideBarWidth = 0
                                        }
                                    }
                                    
                                    lastDragValue = 0
                                }
                        )

                    if store.login.isPresented {
                        LoginDialog(store: self.store)
                    }
                }
                .navigationDestination(item: viewStore.binding(
                    get: \.destination,
                    send: AppReducer.Action.destinationChanged
                )) { destination in
                    switch destination {
                    case .widget:
                        AnyView(widgetFeature.makeView())
                    case .friend:
                        AnyView(friendFeature.makeView())
                    }
                }
            }
        }
        .onAppear() {
            store.send(.onAppear)
        }
    }
}

struct sideBarMenu: View {
    
    let store: StoreOf<AppReducer>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            
            Spacer()
                .frame(height: 20)
            
            if store.login.name == nil {
                Button(action: {
                    store.send(.loginButtonTapped)
                }, label: {
                    Text("로그인")
                        .foregroundStyle(.black)
                })
                .frame(maxWidth: .infinity)
            } else {
                Text("\(store.login.name ?? "") 님 환영합니다.")
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            Divider()
            
            
            Button(action: {
                store.send(.destinationChanged(.widget))
            }, label: {
                Image(systemName: "widget.small")
                Text("위젯")
            })
            .foregroundStyle(.black)
            
            Button(action: {
                store.send(.destinationChanged(.friend))
            }, label: {
                Image(systemName: "person.2")
                Text("친구")
            })
            .foregroundStyle(.black)
            
            Spacer()
            
            if store.login.name != nil {
                Button(action: {
                    store.send(.logout)
                }, label: {
                    Text("로그아웃")
                        .font(.caption2)
                })
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(20)
        .background(.white)
    }
}

struct LoginDialog: View {
    
    let store: StoreOf<AppReducer>
    
    var body: some View {
        
        ZStack {
            
            Rectangle()
                .fill(.gray.opacity(0.3))
                .onTapGesture {
                    store.send(.didCancelLogin)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            LoginView(store: store.scope(state: \.login , action: \.login))
        }
        
        
    }
}

@Reducer
struct AppReducer {
    
    @Dependency(\.calendarFeature) var calendarFeature
    
    init() {
        
    }
    
    @ObservableState
    struct State: Equatable {
        var destination: Destination?
        var didShowLogin: Bool = false
        var login: LoginReducer.State = LoginReducer.State()
    }
    
    enum Action: BindableAction {
        case destinationChanged(AppReducer.Destination?)
        case loginButtonTapped
        case didCancelLogin
        case binding(BindingAction<State>)
        case login(LoginReducer.Action)
        case logout
        case onAppear
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Scope(
            state: \.login,
            action: \.login
        ) {
            LoginReducer()
        }
        
        Reduce { state, action in
            
            switch action {
                
            case .loginButtonTapped:
                state.login.isPresented = true
                return .none
                
            case .didCancelLogin:
                state.login.isPresented = false
                return .none
                
            case .destinationChanged(let destination):
                state.destination = destination
                return .none
                
            case .binding:
                return .none
                
//            case .destination(.presented(.diaryView(.delegate(.addDiary(diary))))):
//                state.diaryData[diary.date.calendarKeyString] = diary
//                return .none
                
            case .login(.delegate(.didSuccessLogin)):
                calendarFeature.sync()
                return .none
                
            case .login:
                return .none
                
            case .logout:
                return .send(.login(.logout))
                
            case .onAppear:
                return .send(.login(.loadUserData))
                
            }
            
        }
    }
}

extension AppReducer {
    public enum Destination: Equatable, Identifiable {
        case widget
        case friend
        
        var id: String {
            switch self {
            case .widget: return "widget"
            case .friend: return "friend"
            }
        }
    }
}
