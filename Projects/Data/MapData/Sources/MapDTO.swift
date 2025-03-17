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
    
    public override init() {
        
    }
    
    public init(sigunguCode: Int, images: [Data], startDate: Date, endDate: Date, memo: String) {
        super.init()
        self.sigunguCode = sigunguCode
        self.images = List()
        self.images.append(objectsIn: images)
        self.startDate = startDate
        self.endDate = endDate
        self.memo = memo
    }
    
    public init(from vo: TripVO) {
        super.init()
        self.sigunguCode = vo.sigunguCode
        self.images = List()
        self.images.append(objectsIn: vo.images)
        self.startDate = vo.startDate
        self.endDate = vo.endDate
        self.memo = vo.memo
    }
    
    public func toVO() -> TripVO {
        return TripVO(sigunguCode: sigunguCode, images: Array(images), startDate: startDate, endDate: endDate, memo: memo)
    }
}

