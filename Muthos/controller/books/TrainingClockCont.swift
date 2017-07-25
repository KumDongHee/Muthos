//
//  TrainingClockCont.swift
//  muthos
//
//  Created by YoungjuneKwon on 2016. 7. 1..
//
//

import UIKit

class TrainingClockCont : UIViewController {
    var mainController:TrainingMainCont?
    
    @IBOutlet var hourImgView: UIImageView!
    @IBOutlet var minuteImgView: UIImageView!
    
    @IBAction func onClickMic(_ sender: AnyObject) {
        if let main = mainController {
            main.onEndGame(1, fail:1)
        }
    }
}
