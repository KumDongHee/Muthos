//
//  ApplicationContext.swift
//  muthos
//
//  Created by shining on 2016. 11. 10..
//
//

import Foundation

class ApplicationContext {
    static let sharedInstance:ApplicationContext = ApplicationContext()
    
    let downloadManager:DownloadManager = DownloadManager()
    let userViewModel:UserViewModel = UserViewModel()
    let sharedBookController:BookController = BookController()
    let soundEffectManager:SoundEffectManager = SoundEffectManager()
    var speechRecognizingView:SpeechRecognizingView = SpeechRecognizingView()
    
    static var currentUser:User {
        get {
            return sharedInstance.userViewModel.currentUserObject()!
        }
    }
    
    init() {
        self.speechRecognizingView = SpeechRecognizingView.loadFromNib()
    }
    
    static func playEffect(code:SOUND_CODE) {
        sharedInstance.soundEffectManager.playWith(code:code)
    }
    
    func pause() {
        if let situationCont = sharedBookController.situationCont {
            if situationCont.progressing {
                situationCont.procListenPaused(true)
            }
        }
    }
    
    func resume() {
        if let situationCont = sharedBookController.situationCont {
            if situationCont.progressing {
                situationCont.procListenPaused(false)
                situationCont.restartBGMOnCurrentSequence()
                situationCont.renderCurrentSequence()
            }
        }
    }
    
    static func getValue(key:String) -> String {
        let dict = ApplicationContext.loadDictionary()
        if let value:Any = dict.value(forKey: key) {
            return String(describing: value)
        }
        else {
            return ""
        }
    }

    static func putValue(key:String, value:String) {
        let dict = ApplicationContext.loadDictionary()
        dict.setValue(value, forKey: key)
        ApplicationContext.saveDictionary(dict: dict)
    }
    
    static let DICT_FILE_PATH:String = "/appcontext.xml"
    
    static func loadDictionary() -> NSMutableDictionary {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let path = documentsPath + DICT_FILE_PATH
        if let result = NSMutableDictionary(contentsOfFile: path) {
            return result
        } else {
            return NSMutableDictionary()
        }
    }
    
    static func saveDictionary(dict:NSMutableDictionary) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let path = documentsPath + DICT_FILE_PATH
        dict.write(toFile: path, atomically: true)
    }
}
