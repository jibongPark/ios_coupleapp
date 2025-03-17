//
//  MapRepository.swift
//  Domain
//
//  Created by 박지봉 on 3/13/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import ComposableArchitecture

public protocol MapRepository {
    func fetchPolygons() -> Effect<PolygonVO>
    func fetchTrips() -> Effect<[Int: TripVO]>
    func updateTrip(_ trip: TripVO)
}
