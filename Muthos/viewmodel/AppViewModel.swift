//
//  AppViewModel.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 21..
//
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyJSON

class AppViewModel {
    //singleton
    static let sharedInstance = AppViewModel()
    
    let notices:BehaviorSubject<[Notice]>
    
    fileprivate init() {
        let sampleNotices = [
            Notice(JSON: ["title":"서버 안정화 안내", "date":Date(timeIntervalSince1970: 10000000), "isNew":true])!,
            Notice(JSON: ["title":"서버 안정화 안내", "date":Date(timeIntervalSince1970: 10000000), "isNew":false])!,
            Notice(JSON: ["title":"서버 안정화 안내", "date":Date(timeIntervalSince1970: 10000000), "isNew":false])!
        ]
        notices = BehaviorSubject(value: sampleNotices)
    }
    
    deinit {
        notices.onCompleted()
    }
}
