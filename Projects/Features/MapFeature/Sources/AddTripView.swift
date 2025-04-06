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
    
    @FocusState private var isFocused: Bool
    @State private var isEditing: Bool = false
    
    var body: some View {
        
        WithViewStore(store, observe: { $0 }) { viewStore in
            Form {
                
                Section(header: Text("일정")) {
                    DatePicker("시작일", selection: $store.startDate.sending(\.setStartDate), displayedComponents: [.date])
                    DatePicker("종료일", selection: $store.endDate.sending(\.setEndDate), in: store.startDate..., displayedComponents: [.date])
                }
                
                Section(header: Text("이미지")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            
                            ForEach(Array(viewStore.images.enumerated()), id: \.offset) { index, object in
                                DraggableImageItemView(
                                    imagePath: object,
                                    onLongPress: {
//                                        store.send(.imageLongPressed(data))
                                    },
//                                    onDragChanged: { translation in
//                                        store.send(.imageDragChanged(data, translation))
//                                    },
//                                    onDragEnded: { translation in
//                                        store.send(.imageDragEnded(data, translation))
//                                    },
                                    onDelete: {
                                        store.send(.deleteImage(index))
                                    }
                                )
                            }
                            
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
                    Button("대표 이미지 설정") {
                        store.send(.scaleImageButtonTapped)
                    }
                }
                
                Section(header: Text("메모")) {
                    TextEditor(text: $store.memo.sending(\.setMemo))
                        .focused($isFocused)
                }
            }
//            .onTapGesture {
//                isFocused = false
//            }
        }
        .sheet(
            item: $store.scope(state: \.imagePicker, action: \.imagePicker)
        ) {  imageStore in
            NavigationStack {
                ImagePickerView(store: imageStore)
            }
        }
        .sheet(
            item: $store.scope(state: \.scalePhoto, action: \.scaleImage)
        ) { scaleStore in
            NavigationStack {
                ScalePhotoView(store: scaleStore)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("취소") {
                    store.send(.cancelButtonTapped)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("저장") {
                    store.send(.saveButtonTapped)
                }
            }
        }
        .navigationTitle(Text(store.polygon.name))
    }
}


struct DraggableImageItemView: View {
    let imagePath: String
    
    let onLongPress: () -> Void
//    let onDragChanged: (CGSize) -> Void
//    let onDragEnded: (CGSize) -> Void
    let onDelete: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isEditing: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = ImageLib.loadImageFromDocument(withFilename: imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)
                    .offset(dragOffset)
                    .gesture(
                        LongPressGesture(minimumDuration: 0.3)
                            .onEnded { _ in
                                isEditing.toggle()
                                onLongPress()
                            }
                    )
                    
//                    .gesture(
//                        DragGesture()
//                            .onChanged { value in
//                                dragOffset = value.translation
//                                onDragChanged(value.translation)
//                            }
//                            .onEnded { value in
//                                onDragEnded(value.translation)
//                                dragOffset = .zero
//                            }
//                    )
            } else {
                Text("Error")
                    .gesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                isEditing.toggle()
                                onLongPress()
                            }
                    )
            }
            
            if isEditing {
                Button(action: {
                    onDelete()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .background(Color.white.clipShape(Circle()))
                }
            }
        }
    }
}
