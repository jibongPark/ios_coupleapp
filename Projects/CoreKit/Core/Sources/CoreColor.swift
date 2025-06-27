//
//  CoreColor.swift
//  Core
//
//  Created by 박지봉 on 6/5/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import SwiftUI
import UIKit

public extension Color {
    
    /// MemoryBox 기본 배경색
    static var mbBackgroundBeige: Color {
        Color(
            UIColor { trait in
                trait.userInterfaceStyle == .dark
                ? UIColor(hex: "1C1C1E")
                : UIColor(hex: "F8F1EA")
            }
        )
    }
    
    static var mbSystemBackground: Color {
        Color(
            UIColor.systemBackground
        )
    }
    
    static var mbBackwardColor: Color {
        Color (
            UIColor { trait in
                trait.userInterfaceStyle == .dark
                ? UIColor(hex: "FFFFFF")
                : UIColor(hex: "000000")
            }
        )
    }
    
    /// MemoryBox 입력 배경색
    static var mbInputBackground = Color(
        
        UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(hex: "2C2C2E")
            : UIColor(hex: "FFFFFF")
        }
    )
    
    /// MemoryBox 주요 버튼 색상
    static let mbPrimaryTerracotta = Color(
        UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(hex: "A45B49")
            : UIColor(hex: "C1765D")
        }
    )
    
    /// MemoryBox 셀 선택 등 색상
    static let mbSecondaryOliveGreen = Color(
        UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(hex: "6E7A65")
            : UIColor(hex: "A3B18A")
        }
    )
    
    /// MemoryBox 버튼 아이콘 등 색상
    static let mbAccentSlateBlue = Color(
        UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(hex: "2E4C7D")
            : UIColor(hex: "4A6FA5")
        }
    )
    
    /// MemoryBox 본문/제목 등 텍스트
    static let mbTextBlack = Color(
        UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(hex: "E5E5E5")
            : UIColor(hex: "000000")
        }
    )
    
    /// MemoryBox 보조 텍스트/ Placeholder
    static let mbTextLightGray = Color(
        UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(hex: "8E8E93")
            : UIColor(hex: "A0A0A0")
        }
    )
}

public extension Color {
    /// 16진수(#RRGGBB)로 Color를 초기화하는 이니셜라이저
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8)  / 255
        let b = Double(rgb & 0x0000FF)         / 255
        self.init(red: r, green: g, blue: b)
    }
}

public extension UIColor {
    
    convenience init(hex: String) {
        let trimHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let dropHash = String(trimHex.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        let hexString = trimHex.starts(with: "#") ? dropHash : trimHex
        let ui64 = UInt64(hexString, radix: 16)
        let value = ui64 != nil ? Int(ui64!) : 0
        // #RRGGBB
        var components = (
            R: CGFloat((value >> 16) & 0xff) / 255,
            G: CGFloat((value >> 08) & 0xff) / 255,
            B: CGFloat((value >> 00) & 0xff) / 255,
            a: CGFloat(1)
        )
        if String(hexString).count == 8 {
            // #RRGGBBAA
            components = (
                R: CGFloat((value >> 24) & 0xff) / 255,
                G: CGFloat((value >> 16) & 0xff) / 255,
                B: CGFloat((value >> 08) & 0xff) / 255,
                a: CGFloat((value >> 00) & 0xff) / 255
            )
        }
        self.init(red: components.R, green: components.G, blue: components.B, alpha: components.a)
    }
    
    func toHex(alpha: Bool = false) -> String? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if alpha {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
