//
//  Response+API.swift
//  CommonData
//
//  Created by 박지봉 on 5/8/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Moya
import Foundation

public extension Response {
    /// 1) 원본 JSON을 APIResponse<Payload> 래퍼로 디코딩
    ///    - message나 data가 없어도 `nil`로 남깁니다.
    func mapAPIResponse<Payload: Decodable>(
        _ payloadType: Payload.Type,
        using decoder: JSONDecoder = JSONDecoder()
    ) throws -> APIResponse<Payload> {
        return try decoder.decode(APIResponse<Payload>.self, from: self.data)
    }
    
    
    func mapAPIResponse(
        using decoder: JSONDecoder = JSONDecoder()
    ) throws -> Response2 {
        return try decoder.decode(Response2.self, from: self.data)
    }
    
    /// 2) 내부 data와 message를 튜플로 꺼내는 편의 메서드
    ///    - data가 없으면 `payload`는 nil
    ///    - message가 없으면 `message`는 nil
    func mapAPIData<Payload: Decodable>(
        _ payloadType: Payload.Type,
        using decoder: JSONDecoder = JSONDecoder()
    ) throws -> (payload: Payload?, message: String?) {
        let wrapper = try mapAPIResponse(payloadType, using: decoder)
        return (wrapper.data, wrapper.message)
    }
}
