//
//  TC.swift
//  muthos
//
//  Created by shining on 2016. 11. 14..
//
//

import Foundation

protocol TC {
    func perform()
}

class TC_Dummy : TC {
    func perform() {}
}

class TC_producer {
    static func perform(for name:String) {
        let tc:TC = TC_producer.tc(for: name)
        tc.perform()
    }
    
    static func tc(for name:String) -> TC {
        switch(name) {
        case "downloading":
                return TC_downloading()
        case "score":
            return TC_score()
        case "dictation":
            return TC_dictation()
        default:
            return TC_Dummy()
        }
    }
}

class Profiler {
    var tag:String = ""
    var begin:NSDate = NSDate()
    var last:NSDate = NSDate()
    
    init(_ tag:String) {
        self.tag = tag
    }
    
    func begin(_ msg:String = "") {
        begin = NSDate()
        last = begin
        print("profile::[ " + self.tag + " ] begin " + msg + " " + begin.description)
    }
    
    func lap(_ msg:String = "") {
        let now:NSDate = NSDate()
        let diff:Double = now.timeIntervalSince1970 - last.timeIntervalSince1970
        print("profile::[ " + self.tag + " ] lap " + msg + " " + String(diff))
        last = now
    }
    
    func end(_ msg:String = "") {
        let now:NSDate = NSDate()
        let diff:Double = now.timeIntervalSince1970 - begin.timeIntervalSince1970
        print("profile::[ " + self.tag + " ] end " + msg + " " + String(diff))
    }
}
