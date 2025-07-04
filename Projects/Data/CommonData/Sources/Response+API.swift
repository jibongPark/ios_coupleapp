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
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [
          .withInternetDateTime,
          .withFractionalSeconds
        ]
        
        decoder.dateDecodingStrategy = .custom { decoder in
          let container = try decoder.singleValueContainer()
          let str = try container.decode(String.self)
          guard let date = isoFormatter.date(from: str) else {
            throw DecodingError.dataCorruptedError(
              in: container,
              debugDescription: "Invalid date: \(str)"
            )
          }
          return date
        }
        
        return try decoder.decode(APIResponse<Payload>.self, from: self.data)
    }
    
    /// 2) 내부 data와 message를 튜플로 꺼내는 편의 메서드
    ///    - data가 없으면 `payload`는 nil
    ///    - message가 없으면 `message`는 nil
    func mapAPIData<Payload: Decodable>(
        _ payloadType: Payload.Type,
        using decoder: JSONDecoder = JSONDecoder()
    ) -> (isSuccess: Bool, payload: Payload?, message: String) {
        
        do {
            let wrapper = try mapAPIResponse(payloadType, using: decoder)
            return (wrapper.success, wrapper.data, wrapper.message ?? "빈 메시지")
        } catch {
            print("통신 실패: \(Payload.Type.self), \(error)")
            return (false, nil, "서버와의 통신에 에러가 발생했습니다.")
        }
    }
}
