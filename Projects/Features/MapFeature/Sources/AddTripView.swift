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
    
    var body: some View {
        
        WithViewStore(store, observe: { $0 }) { viewStore in
            Form {
                DatePicker("시작일", selection: $store.startDate.sending(\.setStartDate), displayedComponents: [.date])
                DatePicker("종료일", selection: $store.endDate.sending(\.setEndDate), in: store.startDate..., displayedComponents: [.date])
                
                Section(header: Text("Images")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(Array(viewStore.images.enumerated()), id: \.element) { index, data in
                                DraggableImageItemView(
                                    imageData: data,
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
                }

                Button("대표 이미지 설정") {
                    store.send(.scaleImageButtinTapped)
                }
                
                TextEditor(text: $store.memo.sending(\.setMemo))
                    .focused($isFocused)
                
                Button("Save") {
                    store.send(.saveButtonTapped)
                }
            }
            .onTapGesture {
                isFocused = false
            }
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
            ToolbarItem {
                Button("Cancel") {
                    store.send(.cancelButtonTapped)
                }
            }
        }
    }
}


struct DraggableImageItemView: View {
    let imageData: Data
    
    let onLongPress: () -> Void
//    let onDragChanged: (CGSize) -> Void
//    let onDragEnded: (CGSize) -> Void
    let onDelete: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isEditing: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)
                    .offset(dragOffset)
                    .gesture(
                        LongPressGesture(minimumDuration: 0.5)
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
                .offset(x: 10, y: -10)
            }
        }
    }
}
