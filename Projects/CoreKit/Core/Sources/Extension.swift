//
//  Extension.swift
//  Core
//
//  Created by 박지봉 on 4/11/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import SwiftUI

public extension View {
    
    func resizingSheet<Item, Content>(item: Binding<Item?>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping (Item) -> Content) -> some View where Item : Identifiable, Content : View {
        
        self.sheet(item: item, onDismiss: onDismiss) { item in
            ResizingSheetContent(item: item, content: content)
        }
    }
}

private struct ResizingSheetContent<Item: Identifiable, Content: View>: View {
    let item: Item
    let content: (Item) -> Content
    
    @State private var measuredHeight: CGFloat = .zero
    
    var body: some View {
        
        content(item)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .task(id: geometry.size.height) {
                            measuredHeight = geometry.size.height
                        }
                }
            )
            .presentationDetents(measuredHeight == .zero ? [.medium] : [.height(measuredHeight)])
    }
}


public extension UIImage {
    func resize(to size: CGSize) -> UIImage {
        let widthRatio  = size.width  / self.size.width
        let heightRatio = size.height / self.size.height
        let scaleFactor = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: self.size.width * scaleFactor, height: self.size.height * scaleFactor)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
