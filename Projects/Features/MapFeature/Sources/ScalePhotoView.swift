//
//  ScalePhotoView.swift
//  MapFeature
//
//  Created by 박지봉 on 3/18/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//


import SwiftUI
import ComposableArchitecture
import MapKit
import Core

struct ScalePhotoView: View {
    @Bindable var store: StoreOf<ScalePhotoReducer>
    
    var body: some View {
        GeometryReader { geometry in
            let shape = MultiPolygonShape(
                multiPolygon: store.polygonShape,
                boundingRect: store.polygonShape.polygon.boundingMapRect
            )
            
            let frame = CGRect(
                origin: .zero,
                size: CGSize(width: geometry.size.width,
                             height: geometry.size.height)
                )
            
            let shapeRect = shape.path(in: frame).boundingRect
            
            let centerX = shapeRect.midX
            let centerY = shapeRect.midY
            
            let position = CGPoint(x: centerX * store.position.x,
                                   y: centerY * store.position.y)
            
            ZStack {
                if let uiImage = ImageLib.loadImageFromDocument(withFilename: store.imagePath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: shapeRect.width, height: shapeRect.height)
                        .scaleEffect(CGFloat(store.scale))
                        .position(position)
                        .mask {
                            shape.frame(width: geometry.size.width, height: geometry.size.height)
                        }
                }
                
                shape
                    .stroke(Color.gray, lineWidth: 1)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
            }
            .gesture(
                SimultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            store.send(.didChangePosition(
                                CGPoint(x: value.location.x / centerX,
                                        y: value.location.y / centerY))
                            )
                        },
                    MagnificationGesture()
                        .onChanged { value in
                            store.send(.didChangeScale(Float(value)))
                        }
                )
            )
        }
        .navigationBarTitle("Scale Photo", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    store.send(.doneButtonTapped)
                }
            }
        }
    }
}
