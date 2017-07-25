//
//  Pet.swift
//  Muthos
//
//  Created by shining on 2016. 9. 3..
//
//

import Foundation

class Pet {
    var name:String = ""
    var faceImage:UIImage = UIImage()
    var bodyImage:UIImage = UIImage()
    var offeringRetry:Int = 0
    var offeringCoin:Int = 0
    var dcRate:Float = 0
    
    var lastEarned:TimeInterval = 0
    
    init() {}
    init(name:String, dc:Float, retry:Int, coin:Int) {
        self.name = name
        self.dcRate = dc
        self.offeringCoin = coin
        self.offeringRetry = retry
    }
}
