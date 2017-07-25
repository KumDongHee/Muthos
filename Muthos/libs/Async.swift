//
//  Async.swift
//  Muthos
//
//  Created by Youngjune Kwon on 2016. 1. 30..
//  Copyright © 2016년 김성재. All rights reserved.
//

import Foundation

open class Async {
    public typealias callbackWithParam = (_ param:AnyObject) -> Bool
    public typealias callbackFunc = () -> Bool
    public typealias asyncEachFunc = (AnyObject, @escaping callbackFunc) -> Void
    public typealias seriesEachFunc = (@escaping callbackFunc) -> Void
    
    open class func eachSeries(_ array:[AnyObject], eachFunc:@escaping asyncEachFunc, callback:@escaping callbackFunc) {
        func each(_ array:[AnyObject], eachFunc:@escaping asyncEachFunc, idx:Int) {
            if idx >= array.count {
                _ = callback()
                return
            }
            
            eachFunc(array[idx], {() -> Bool in
                each(array, eachFunc:eachFunc, idx:idx+1)
                return true
            } )
        }
        each(array, eachFunc:eachFunc, idx:0)
    }
    
    open class func series(_ funcs:[seriesEachFunc], callback:@escaping callbackFunc) {
        func each(_ funcs:[seriesEachFunc], idx:Int) {
            if idx >= funcs.count {
                _ = callback()
                return
            }
            
            funcs[idx]({() -> Bool in
                each(funcs, idx:idx+1)
                return true
            } )
        }
        each(funcs, idx:0)
    }
}
