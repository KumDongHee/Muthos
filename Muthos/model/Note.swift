//
//  Note.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 27..
//
//

import Foundation
import ObjectMapper
import SwiftyJSON

class Note: Mappable {
    var _id:String?
    var contents:String?
    var date:Date?
    var thumbimage:String?
    var rating:Float?
    var bookId:String?
    var bookTitle:String?
    var voice:String?
    var setIndex:String?
    var key:String?
    var backgroundImage:UIImage?
    var dialog:JSON?
    
    required init?(map: Map) {
    }
    
    // Mappable
    func mapping(map: Map) {
        _id <- map["_id"]
        contents <- map["contents"]
        date <- map["date"]
        thumbimage <- map["thumbimage"]
        rating <- map["rating"]
        bookId <- map["bookId"]
        bookTitle <- map["bookTitle"]
        voice <- map["voice"]
        setIndex <- map["setIndex"]
        key <- map["key"]
    }
}
