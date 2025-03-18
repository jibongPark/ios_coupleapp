//
//  AddTripView.swift
//  MapFeature
//
//  Created by 박지봉 on 3/13/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//


import SwiftUI
import ComposableArchitecture
import Core

struct AddTripView: View {
    @Bindable var store: StoreOf<AddTripReducer>
    
    var body: some View {
        
        WithViewStore(store, observe: { $0 }) { viewStore in
            Form {
                DatePicker("시작일", selection: $store.startDate.sending(\.setStartDate), displayedComponents: [.date])
                DatePicker("종료일", selection: $store.endDate.sending(\.setEndDate), in: store.startDate..., displayedComponents: [.date])
                Section(header: Text("Images")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(store.images, id: \.self) { data in
                                
                                if let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipped()
                                        .cornerRadius(8)
                                } else {
                                    Text("error")
                                }
                            }
                            // 이미지 추가 버튼
                            Button {
                                store.send(.addImageButtonTapped)
                            } label: {
                                Image(systemName: "plus.circle")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                TextField("memo", text: $store.memo.sending(\.setMemo))
                Button("Save") {
                    store.send(.saveButtonTapped)
                }
            }
        }
        .sheet(
            item: $store.scope(state: \.imagePicker, action: \.imagePicker)
        ) {  imageStore in
            NavigationStack {
                ImagePickerView(store: imageStore)
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Cancel") {
                    store.send(.cancelButtonTapped)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddTripView(store: Store(
            initialState: AddTripReducer.State(
                sigunguCode: 1,
                startDate: Date.now
                )
        ) {
            AddTripReducer()
        }
                    )
    }
}
