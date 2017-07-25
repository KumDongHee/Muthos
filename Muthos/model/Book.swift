//
//  Book.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 23..
//  Copyright © 2016년 김성재. All rights reserved.
//

import UIKit
import ObjectMapper

class Book: Mappable {
    var _id:String?
    var name:String?
    var thumbimage:String?
    var purchased:Bool = false
    var bookmarked:Bool = false
    var sets:[BookSet] = []
    required init?(map: Map) {
    }
    
    // Mappable
    func mapping(map: Map) {
        _id <- map["_id"]
        name <- map["name"]
        thumbimage <- map["thumbimage"]
        purchased <- map["purchased"]
        bookmarked <- map["bookmarked"]
    }
}

class BookSet: Mappable {
    var _id:String?
    var index:Int?
    var title:String?
    var type:String?
    var isBonus:Bool! {
        get {
            if let t:String = self.type {
                if "roulette" == t {
                    return true
                }
            }
            return false
        }
    }
    var rating:CGFloat?
    var coverImage:String?
    var speakerThumbnail:String?
    
    required init?(map: Map) {
    }
    
    // Mappable
    func mapping(map: Map) {
        _id <- map["_id"]
        index <- map["index"]
        title <- map["title"]
        rating <- map["rating"]
        coverImage <- map["coverImage"]
        type <- map["type"]
        speakerThumbnail <- map["speakerThumbnail"]
    }
}
