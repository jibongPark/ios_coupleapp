//
//  AddDDayView.swift
//  WidgetFeature
//
//  Created by 박지봉 on 4/11/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import Domain
import Core


struct AddDDayView: View {
    
    @Bindable var store: StoreOf<AddDDayReducer>
    
    @State var subHeight: CGFloat = .zero
     
    init(store: StoreOf<AddDDayReducer>) {
        self.store = store
    }
    
    let scale: CGFloat = 0.3
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    ZStack {
                        
                        // TODO: 이미지 선택시 scale 조정 및 크기 조정 로직 필요
                        if let image = store.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height * scale + geometry.safeAreaInsets.top)
                                .clipped()
                        } else {
                            if let image = ImageLib.loadImageFromGroup(withFilename: store.imagePath, groupName: "group.com.bongbong.coupleapp") {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width, height: geometry.size.height * scale + geometry.safeAreaInsets.top)
                                    .clipped()
                            }
                        }
                    
                        
                        Text(store.startDate.dDayString)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                            .padding(.top, geometry.safeAreaInsets.top)
                        
                        
                        Button(action: {
                            store.send(.addPhotoButtonTapped)
                        }) {
                            Image(systemName: "photo.artframe.circle.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 10)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                    .ignoresSafeArea(.all, edges:.top)
                    .frame(width: geometry.size.width, height: geometry.size.height * scale, alignment: .top)
                    
                    
                    
                    VStack {
                        
                        TextField("", text: $store.title)
                            .font(.title2.bold())
                            .foregroundStyle(.gray)
                            .overlay(alignment: .topLeading) {
                                if store.title.isEmpty {
                                    Text("디데이 제목을 입력하세요.")
                                        .font(.title2.bold())
                                        .foregroundStyle(.gray)
                                        .allowsHitTesting(false)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                        
                        Divider()
                            .background(.gray)
                        
                        HStack(spacing: 0) {
                            
                            Text("처음 만난 날")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(.gray)
                            
                            Button(action: {
                                store.send(.dateChangeButtonTapped)
                            }) {
                                HStack {
                                    Text(store.startDate.formattedDateString)
                                        .frame(alignment: .trailing)
                                        .foregroundStyle(.gray)
                                    
                                    Image(systemName: store.destination != nil ? "chevron.up" : "chevron.down")
                                        .foregroundStyle(.gray)
                                    
                                    
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(5)
                        
                        Divider()
                            .background(.gray)
                        
                        Spacer()
                        
                    }
                    .ignoresSafeArea(.all, edges:.top)
                    .padding(10)
                    .frame(height: geometry.size.height * (1-scale), alignment: .top)
                    .background(Color.black.opacity(0.9))
                }
            }
            .toolbar {
                Group {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            store.send(.cancelButtonTapped)
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("저장") {
                            store.send(.saveButtonTapped)
                        }
                        .foregroundColor(.gray)
                    }
                }
            }
        }
        .sheet(item: $store.scope(state: \.destination?.photoPicker, action: \.destination.photoPicker)) { store in
            ImagePickerView(store: store)
        }

        .resizingSheet(item: $store.scope(state: \.destination?.datePicker, action: \.destination.datePicker)) { store in
            DatePickerView(store: store)
        }
    }
}

extension Date {
    var formattedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd E"
        return formatter.string(from: self)
    }
}



#Preview {
    AddDDayView(store: Store(initialState: AddDDayReducer.State()) {
        AddDDayReducer()
    })
}
