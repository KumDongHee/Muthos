//
//  ScoreCont.swift
//  muthos
//
//  Created by YoungjuneKwon on 2016. 3. 30..
//
//

import UIKit
import SwiftyJSON
import SwiftAnimations

extension UIView{
    func findChildByTag(_ tag:Int) -> UIView? {
        func doFind(_ v:UIView) -> UIView? {
            if v.subviews.count == 0 {
                return nil
            }
            for c:UIView in v.subviews {
                if tag == c.tag {
                    return c
                }
                else {
                    if let t:UIView = doFind(c) {
                        return t
                    }
                }
            }
            return nil
        }
        return doFind(self)
    }
}

class ScoreCont : UIViewController {

    @IBOutlet weak var gradeArea: UIView!
    @IBOutlet weak var prizeArea: UIView!
    @IBOutlet weak var graphArea: UIView!
    @IBOutlet weak var buttonArea: UIView!
    @IBOutlet weak var gradeIconImage: UIImageView!
    @IBOutlet weak var gradeMentImage: UIImageView!
    @IBOutlet weak var prizeCoinArea: UIView!
    @IBOutlet weak var prizeRetryArea: UIView!
    @IBOutlet weak var prizeCoinText: UILabel!
    @IBOutlet weak var prizeRetryText: UILabel!
    @IBOutlet var gradeRows: [UIView]!
    @IBOutlet weak var totalText: UIView!
    @IBOutlet weak var buttonOriginGuide: UIView!
    @IBOutlet weak var buttonWrap: UIView!
    @IBOutlet weak var button: UIButton!
    
    var onClose:Async.callbackFunc?
    
    var controller:BookController?
    var model:Dictionary<String, AnyObject>?
    override func viewDidLoad() {
        buttonWrap.layer.cornerRadius = buttonWrap.frame.height / 2
    }
    
    func reload() {
        resetUI()
        self.model = controller?.evaluateScoreModel()

        guard let model = model else { return }
        guard let controller = controller else { return }
        guard let book = controller.book else { return }

        let user = ApplicationContext.currentUser
        let setIndex = controller.model!["sets"][controller.selectedIdx!]["index"].stringValue
        
        let currentGrade = model["grade"] as! Int
        let lastGrade = user.lastGrade(bookId:book._id!, setIndex:setIndex, bookMode:controller.bookMode)
        let completed = user.isCompleted(bookId:book._id!, setIndex:setIndex, bookMode:controller.bookMode)

        let diffGrade = currentGrade - lastGrade
        let coin = diffGrade > 0
            ? (BookController.coinRewardFor(currentGrade) as! Int) - (BookController.coinRewardFor(lastGrade) as! Int)
            : 0

        let total = self.model!["total"] as! Int
        var counts = self.model!["counts"] as! [Int]
        let grade = diffGrade > 0 ? currentGrade : lastGrade
        let retry = completed ? 0 : self.model!["retry"] as! Int

        let gradeIcons:[String] = ["grade_icon_star_empty", "grade_icon_star_fill_01", "grade_icon_star_fill_02", "grade_icon_star_fill_03", "grade_icon_crown"]
        let gradeMents:[String] = ["grade_result_30","grade_result_50","grade_result_70","grade_result_90","grade_result_100"]
        
        gradeIconImage.image = UIImage(named: gradeIcons[grade-1])
        gradeMentImage.image = UIImage(named: gradeMents[grade-1])
        prizeCoinText.text = "+"+String(coin)
        prizeRetryText.text = "+"+String(retry)
        
        for (i, g) in gradeRows.enumerated() {
            let idx:Int = gradeRows.count - i
            self.setGraph(g, count: counts[idx], total:total)
        }
        
        (totalText.findChildByTag(200) as! UILabel).text = String(total)
        
        user.updateSetCompleted(bookId:book._id!, setIndex:setIndex, bookMode:controller.bookMode, completed : 1)
        user.updateLastGrade(bookId:book._id!, setIndex:setIndex, bookMode:controller.bookMode, grade : grade)
        if coin > 0 { _ = user.appendCoin(coin, memo:"") }
        if retry > 0 { user.appendRetry(retry, memo:"") }
        ApplicationContext.sharedInstance.userViewModel.updateUser(user)
    }
    
    func setGraph(_ g:UIView, count:Int, total:Int) {
        let marginRight:CGFloat = 99
        let barFrame:UIView? = g.findChildByTag(100)
        let bar:UIView? = g.findChildByTag(110)
        let rate:UIView? = g.findChildByTag(120)
        let cnt:UIView? = g.findChildByTag(200)
        let r:CGFloat = CGFloat(count) / CGFloat(total)
        let MARGIN_BAR:CGFloat = 5
        let screenRect:CGRect = UIScreen.main.bounds
        
        if barFrame != nil && bar != nil && rate != nil {
            barFrame?.translatesAutoresizingMaskIntoConstraints = true
            var frame:CGRect = (barFrame?.frame)!
            frame.size.width = screenRect.width - frame.origin.x - marginRight
            barFrame?.frame = frame
            
            bar?.translatesAutoresizingMaskIntoConstraints = true
            rate?.translatesAutoresizingMaskIntoConstraints = true
            (rate as! UILabel).text = String(Int(r * 100)) + "%"
            
            let w:CGFloat = (barFrame!.width - rate!.width - MARGIN_BAR * 2) * r

            bar?.setWidth(w)
            rate?.setX(w + MARGIN_BAR)
            
            bar!.layer.cornerRadius = bar!.height / 2
        }
        
        if cnt != nil {
            (cnt as! UILabel).text = String(count)
        }
    }
    
    func resetUI() {
        buttonWrap.setX(35)
        print(buttonWrap.frame)
        button.setImage(UIImage(named: "grade_btn_ok_default"), for: UIControlState())
        buttonArea.setNeedsLayout()
        buttonArea.setNeedsDisplay()
        buttonWrap.setNeedsLayout()
        buttonWrap.setNeedsDisplay()
        button.setNeedsLayout()
        button.setNeedsDisplay()
    }
    
    @IBAction func onOk(_ sender: AnyObject) {
        if let on = self.onClose {
            _ = on()
        }
        else {
            self.resetUI()
        }
    }
}
