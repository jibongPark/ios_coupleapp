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
    
    @Bindable var store: StoreOf<AppReducer>
    
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
                            .foregroundStyle(Color.mbPrimaryTerracotta)
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
            .tint(.mbPrimaryTerracotta)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
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
                        .foregroundStyle(Color.mbTextBlack)
                })
                .frame(maxWidth: .infinity)
            } else {
                Text("\(store.login.name ?? "") 님 환영합니다.")
                    .foregroundStyle(Color.mbTextBlack)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            Divider()
            
            
            Button(action: {
                store.send(.destinationChanged(.widget))
            }, label: {
                Image(systemName: "widget.small")
                Text("위젯")
                    
            })
            .foregroundStyle(Color.mbTextBlack)
            
            Button(action: {
                store.send(.destinationChanged(.friend))
            }, label: {
                Image(systemName: "person.2")
                Text("친구")
            })
            .foregroundStyle(Color.mbTextBlack)
            
            Spacer()
            
            if store.login.name != nil {
                
                HStack {
                    
                    Button(action: {
                        store.send(.didTapDeleteUser)
                    }, label: {
                        Text("회원탈퇴")
                            .font(.caption2)
                    })
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    
                    Button(action: {
                        store.send(.logout)
                    }, label: {
                        Text("로그아웃")
                            .font(.caption2)
                    })
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding(20)
        .background(Color.mbBackgroundBeige)
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
        
        @Presents var alert: AlertState<Action.Alert>?
        
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
        
        case didTapDeleteUser
        case deleteUser
        
        case alert(PresentationAction<Alert>)
        case showAlert(_ message: String, _ buttons: [ButtonState<Action.Alert>]? = nil)
        @CasePathable
        public enum Alert: Equatable {
            case dismiss
            case deleteUser
        }
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
                
            case .logout:
                return .send(.login(.logout))
                
            case .didTapDeleteUser:
                return .send(.showAlert("회원탈퇴를 하시겠습니까?\n 모든 데이터가 사라지며 복구 불가합니다.", [
                    ButtonState(action: .deleteUser, label: {
                        TextState("확인")
                    })
                ]))
                
            case .deleteUser:
                return .send(.login(.deleteUser))
                
            case .login(.delegate(.didDeleteUser(let message))):
                return .merge([
                    .send(.logout),
                    .send(.showAlert(message))
                ])
                
            case .login:
                return .none
                
            case let .showAlert(message, buttons):
                
                var allButtons: [ButtonState<Action.Alert>] = [
                    ButtonState(action: .dismiss, label: {
                        TextState("취소")
                    })
                ]
                
                if let buttons = buttons {
                    allButtons.append(contentsOf: buttons)
                }
                
                state.alert = AlertState {
                    TextState(message)
                } actions: {
                    for button in allButtons {
                        button
                    }
                }
                
                return .none
                
            case .alert(.presented(.dismiss)):
                state.alert = nil
                return .none
                
            case .alert(.presented(.deleteUser)):
                return .send(.deleteUser)
                
            case .alert:
                return .none
                
            case .onAppear:
                return .send(.login(.loadUserData))
                
            }
            
        }
        .ifLet(\.$alert, action: \.alert)
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
