//
//  FriendViewModel.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 18..
//
//

import Foundation
import RxSwift
import RxCocoa

class FriendViewModel {
    
    let friendMode:BehaviorSubject<FriendMode> = BehaviorSubject(value: .friendList)
    
    var disposeBag:DisposeBag!
    
    init() {
        disposeBag = DisposeBag()
        
    }
    
    deinit {
        disposeBag = nil
    }
}

