//
//  SpeechRecognizer.swift
//  Muthos
//
//  Created by Youngjune Kwon on 2016. 2. 20..
//  Copyright © 2016년 김성재. All rights reserved.
//

import Foundation

protocol SpeechRecognizingDelegate {
    func speechRecognizing(_ speechRecognizing:SpeechRecognizing, listening:String, level:Float)
}

protocol SpeechRecognizing {
    var recognized:String {get}
    
    func recognize(withAnswer:String, callback:@escaping Async.callbackFunc) -> Bool
    func stopRecognizing()
    func setDelegate(_ delegate:SpeechRecognizingDelegate?)
    
    func getOnRecognize() -> Bool
}
