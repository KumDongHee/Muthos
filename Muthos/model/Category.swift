//
//  Category.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 23..
//  Copyright © 2016년 김성재. All rights reserved.
//

import UIKit
import ObjectMapper

class Category: Mappable {
    var _id:String?
    var name:String?
    var books:[Book] = []
    
    required init?(map: Map) {
    }
    
    // Mappable
    func mapping(map: Map) {
        _id <- map["_id"]
        name <- map["name"]
    }
}
