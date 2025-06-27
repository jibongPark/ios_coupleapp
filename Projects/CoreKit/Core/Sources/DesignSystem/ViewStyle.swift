//
//  Extension.swift
//  Core
//
//  Created by 박지봉 on 6/27/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import SwiftUI

public struct InputStyle: ViewModifier {
    
    let backgroundColor: Color = Color.mbInputBackground
    let foregroundColor: Color = Color.mbTextBlack
    
    public func body(content: Content) -> some View {
        content
            .padding(12)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
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

public struct InputBackgroundColor: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(Color.mbInputBackground)
    }
}

public struct BackgroundColor: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(Color.mbBackgroundBeige)
    }
}

public struct InputColor: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .foregroundColor(.mbTextBlack)
    }
}

public extension View {
    func inputStyle(foregroundColor: Color = Color.mbTextBlack, backgroundColor: Color = Color.mbInputBackground) -> some View {
        modifier(InputStyle())
    }
    
    func backgroundStyle() -> some View {
        modifier(BackgroundStyle())
    }
    
    func setInputBackgroundColor() -> some View {
        modifier(InputBackgroundColor())
    }
    
    func setBackgroundColor() -> some View {
        modifier(BackgroundColor())
    }
    
    func setInputColor() -> some View {
        modifier(InputColor())
    }
}
