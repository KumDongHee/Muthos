//
//  Tooltip.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 21..
//
//

import Foundation
import ObjectMapper
import UIKit

class TooltipCategory: Mappable {
    var _id:String?
    var title:String?
    var tooltips:Array<Tooltip>?
    
    required init?(map: Map) {
    }
    
    // Mappable
    func mapping(map: Map) {
        _id <- map["_id"]
        title <- map["title"]
        tooltips <- map["tooltips"]
    }
}

class Tooltip: Mappable {
    var _id:String?
    var contents:String?
    var image:UIImage?
    
    required init?(map: Map) {
    }
    
    // Mappable
    func mapping(map: Map) {
        _id <- map["_id"]
        contents <- map["contents"]
        image <- map["image"]
    }
}
