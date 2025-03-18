//
//  MapDTO.swift
//  MapData
//
//  Created by 박지봉 on 3/15/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import Domain

import RealmSwift

final class TripDTO: Object {
    
    @Persisted(primaryKey: true) public var sigunguCode: Int
    @Persisted public var images: List<Data>
    @Persisted public var startDate: Date
    @Persisted public var endDate: Date
    @Persisted public var memo: String
    @Persisted public var scale: Float
    @Persisted public var centerX: Float
    @Persisted public var centerY: Float
    
    public override init() {
        
    }
    
    public init(sigunguCode: Int, images: [Data], startDate: Date, endDate: Date, memo: String, scale: Float, centerX: Float, centerY: Float) {
        super.init()
        self.sigunguCode = sigunguCode
        self.images = List()
        self.images.append(objectsIn: images)
        self.startDate = startDate
        self.endDate = endDate
        self.memo = memo
        self.scale = scale
        self.centerX = centerX
        self.centerY = centerY
    }
    
    public init(from vo: TripVO) {
        super.init()
        self.sigunguCode = vo.sigunguCode
        self.images = List()
        self.images.append(objectsIn: vo.images)
        self.startDate = vo.startDate
        self.endDate = vo.endDate
        self.memo = vo.memo
        self.scale = vo.scale
        self.centerX = Float(vo.center.x)
        self.centerY = Float(vo.center.y)
    }
    
    public func toVO() -> TripVO {
        return TripVO(sigunguCode: sigunguCode, images: Array(images), startDate: startDate, endDate: endDate, memo: memo, scale: scale, center: CGPoint(x: CGFloat(centerX), y: CGFloat(centerY)))
    }
}

