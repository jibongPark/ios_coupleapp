//
//  APIResponse.swift
//  CommonData
//
//  Created by 박지봉 on 5/8/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

public struct APIResponse<Payload: Decodable>: Decodable {
    public let success: Bool
    public let message: String?
    public let data: Payload?
}

