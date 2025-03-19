//
//  MapVO.swift
//  Domain
//
//  Created by 박지봉 on 3/13/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import SwiftUICore
import MapKit

public struct PolygonData: Equatable {
    public let sigunguCode: Int
    public let name: String
    public let polygon: MKMultiPolygon
    
    public init(sigunguCode: Int, name: String, polygon: MKMultiPolygon) {
        self.sigunguCode = sigunguCode
        self.name = name
        self.polygon = polygon
    }
}

public struct PolygonVO: Equatable {
    public static func == (lhs: PolygonVO, rhs: PolygonVO) -> Bool {
        return lhs.boundingRect.size.width == rhs.boundingRect.size.width &&
               lhs.boundingRect.size.height == rhs.boundingRect.size.height &&
               lhs.polygons == rhs.polygons
    }
    
    public let polygons: [PolygonData]
    public let boundingRect: MKMapRect
    
    public init(polygons: [PolygonData], boundingRect: MKMapRect) {
        self.polygons = polygons
        self.boundingRect = boundingRect
    }
}

public struct TripVO: Equatable, Decodable {
    public let sigunguCode: Int
    public let images: [String]
    public let startDate: Date
    public let endDate: Date
    public let memo: String
    public let scale: Float
    public let center: CGPoint
    
    public init(sigunguCode: Int, images: [String], startDate: Date, endDate: Date, memo: String, scale: Float, center: CGPoint) {
        self.sigunguCode = sigunguCode
        self.images = images
        self.startDate = startDate
        self.endDate = endDate
        self.memo = memo
        self.scale = scale
        self.center = center
    }
    
    public func imageAtIndex(_ index: Int) -> String? {
        guard index >= 0 && index < images.count else { return nil }
        return images[index]
    }
}
