//
//  TextButton.swift
//  Core
//
//  Created by 박지봉 on 6/27/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import SwiftUI

public struct TextButton: View {
    private let action: () -> Void
    private let title: LocalizedStringKey
    private let font: Font?
    private let foreground: Color
//    private let background: Color

    public init(_ title: LocalizedStringKey,
                font: Font? = .body,
                foreground: Color = .mbPrimaryTerracotta,
//                background: Color = .mbPrimaryTerracotta,
                action: @escaping () -> Void) {
        self.title = title
        self.font = font
        self.foreground = foreground
//        self.background = background
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            SwiftUI.Text(title)
                .font(font)
                .foregroundColor(foreground)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
//                .background(background)
                .cornerRadius(8)
        }
    }
}
