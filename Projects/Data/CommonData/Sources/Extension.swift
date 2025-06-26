//
//  Extension.swift
//  CommonData
//
//  Created by 박지봉 on 6/25/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Core
import Moya

public extension DataResult {
    init<DTO: Decodable>(
        _ moyaResult: Result<Moya.Response, MoyaError>,
        dtoType: DTO.Type,
        transform: (DTO) -> Payload?) {
            
            switch moyaResult {
            case .success(let response):
                
                let (isSuccess, dto, message): (Bool, DTO?, String) = response.mapAPIData(DTO.self)
                
                
                var vo: Payload? = nil
                
                if let dto = dto {
                    vo = transform(dto)
                }
                
                self.init(isSuccess: isSuccess, data: vo, message: message)
                
            case .failure(let error):
                
                guard let (_, _, message): (Bool, DTO?, String) = error.response?.mapAPIData(DTO.self) else {
                    self.init(message: "서버의 응답이 없습니다. 관리자에게 문의해주세요.")
                    return
                }
                
                self.init(message: message)
            }
        }
}
