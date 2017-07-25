//
//  Request.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 21..
//  Copyright © 2016년 김성재. All rights reserved.
//

import Foundation
import RxAlamofire
import ObjectMapper
import Alamofire
import RxSwift
import AlamofireObjectMapper

extension DataRequest  {
    public func rx_object<T: Mappable>(keyPath: String? = nil) -> Observable<(HTTPURLResponse, T)> {
        return rx.responseResult(responseSerializer: DataRequest.ObjectMapperSerializer(keyPath))
    }
    
    public func rx_array<T: Mappable>(keyPath: String? = nil) -> Observable<(HTTPURLResponse, [T])> {
        return rx.responseResult(responseSerializer: DataRequest.ObjectMapperArraySerializer(keyPath))
    }
}
