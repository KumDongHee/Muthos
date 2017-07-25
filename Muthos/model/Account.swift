//
//  Account.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 20..
//  Copyright © 2016년 김성재. All rights reserved.
//

import Foundation
import UIKit
import ObjectMapper

class Account : Mappable {
    var _id:String?
    var facebookid:String?
    var email:String?
    var password:String?
    var nickname:String?
    var profileurl:String?
    var coin:Int = 0
    var token:String?
    var gender:String?
    var birthday:Date?
    
    required init?(map: Map) {
    }
    
    // Mappable
    func mapping(map: Map) {
        _id <- map["_id"]
        facebookid <- map["facebookid"]
        email <- map["email"]
        password <- map["password"]
        nickname <- map["nickname"]
        profileurl <- map["profileurl"]
        coin <- map["coin"]
        token <- map["token"]
        gender <- map["gender"]
        birthday <- map["birthday"]
    }
}

