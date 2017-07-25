//
//  constants.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 17..
//
//

import Foundation
import UIKit

let MENU_WIDTH:CGFloat = 77.0

// MARK: - Enum
enum MainMode {
    case store
    case myBook
}

enum FriendMode {
    case friendList
    case giftReceived
}

enum LanguageMode: Int {
    case english = 0
    case korean = 1
    case chinese = 2
    
    var value : String {
        switch self {
        case .english: return "English"
        case .korean: return "한국어"
        case .chinese: return "中文"
        }
    }
}

enum AgeMode: Int {
    case all = 0
    case twelve = 1
    case fifteen = 2
    case nineteen = 3
    
    var value : String {
        switch self {
        case .all: return "전체"
        case .twelve: return "12세"
        case .fifteen: return "15세"
        case .nineteen: return "19세"
        }
    }
}
