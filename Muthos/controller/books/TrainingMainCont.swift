//
//  TrainingMainCont.swift
//  muthos
//
//  Created by YoungjuneKwon on 2016. 6. 23..
//
//

import UIKit

class TrainingMainCont : UIViewController {
    var controller:BookController?
    var game:UIViewController?
    
    @IBOutlet weak var bgImgView: UIImageView!
    @IBOutlet weak var titleImgView: UIImageView!
    @IBOutlet weak var profileImgView: UIImageView!
    @IBOutlet var buddyRows: [UIView]!
    
    @IBOutlet var circleViews: [UIImageView]!
    
    override func viewDidLoad() {
        edgesForExtendedLayout = UIRectEdge()
        
        loadBackgroundImage()
        loadTitleImage()
        loadProfileImage()
        initCircleViews()
    }
    
    func loadTitleImage() {
    }
    
    func loadProfileImage() {
    }
    
    func loadBackgroundImage() {
        let img:String = controller!.model!["sets"][0]["coverImage"].stringValue
        if img.hasPrefix("/") {
            bgImgView.image = UIImage(data: (controller?.cachedBookResourceData(img))!)
        }
        else {
            bgImgView.image = UIImage(named: img)
        }
    }
    
    func initCircleViews() {
        for v in circleViews {
            _ = v.circle()
        }
    }
    
    @IBAction func onClickStart(_ sender: AnyObject) {
        startGame()
    }
    
    func gameType() -> String {
        let arr:[String] = controller!.model!["category"].string!.components(separatedBy: "/")
        return arr[1]
    }
    
    func startGame() {
        let type:String = gameType()
        if "clock" == type {
            let cont:TrainingClockCont = BookController.loadViewController("TrainingClock", viewcontroller: "TrainingClockCont") as! TrainingClockCont
            cont.mainController = self
            game = cont
        }
        
        if let g = game {
            view.addSubview(g.view)
        }
        else {
            onEndGame(1,fail:1)
        }
    }
    
    func onEndGame(_ success:Int, fail:Int) {
        if let g = game {
            g.view.removeFromSuperview()
        }
        let grade:TrainingGradeCont = BookController.loadViewController("TrainingCommon", viewcontroller: "TrainingGradeCont") as! TrainingGradeCont
        
        grade.setScore(success, fail:fail, last:8)
//        view.addSubview(grade.view)
    }
}
