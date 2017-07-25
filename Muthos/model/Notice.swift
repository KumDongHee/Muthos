//
//  Notice.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 20..
//
//

import Foundation
import ObjectMapper
import UIKit

class Notice: Mappable {
    var _id:String?
    var title:String?
    var contents:String?
    var date:Date?
    var isNew:Bool?
    
    required init?(map: Map) {
    }
    
    // Mappable
    func mapping(map: Map) {
        _id <- map["_id"]
        title <- map["title"]
        contents <- map["contents"]
        date <- map["date"]
        isNew <- map["isNew"]
    }
}
