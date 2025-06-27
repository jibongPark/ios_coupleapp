//
//  Extension.swift
//  Core
//
//  Created by 박지봉 on 6/27/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import SwiftUI

public struct InputStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(12)
            .background(Color.mbInputBackground)
            .foregroundColor(.mbTextBlack)
            .cornerRadius(8)
    }
}

public struct BackgroundStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(12)
            .background(Color.mbInputBackground)
            .cornerRadius(8)
    }
}

public struct BackgroundColor: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(Color.mbInputBackground)
    }
}

public struct InputColor: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .foregroundColor(.mbTextBlack)
    }
}

public extension View {
    func inputStyle() -> some View {
        modifier(InputStyle())
    }
    
    func backgroundStyle() -> some View {
        modifier(BackgroundStyle())
    }
    
    func setBackgroundColor() -> some View {
        modifier(BackgroundColor())
    }
    
    func setInputColor() -> some View {
        modifier(InputColor())
    }
}
