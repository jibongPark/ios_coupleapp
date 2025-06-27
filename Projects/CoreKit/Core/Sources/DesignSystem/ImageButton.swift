//
//  ImageButton.swift
//  Core
//
//  Created by 박지봉 on 6/27/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import SwiftUI

public struct ImageButton: View {
    private let systemName: String
    private let tint: Color
    private let action: () -> Void

    public init(
        _ systemName: String,
        tint: Color = .mbPrimaryTerracotta,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .foregroundStyle(tint)
        }
    }
}
