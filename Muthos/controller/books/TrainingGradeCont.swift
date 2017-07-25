//
//  TrainingGradeCont.swift
//  muthos
//
//  Created by YoungjuneKwon on 2016. 7. 1..
//
//

import UIKit

class TrainingGradeCont : UIViewController {
    var success:Int = 0
    var fail:Int = 0
    var last:Int = 0
    var total:Int = 0
    
    @IBOutlet weak var scoreArea: UIView!
    
    @IBOutlet weak var lastArea: UIView!
    @IBOutlet weak var currentArea: UIView!
    
    @IBOutlet weak var current10Digit: UIImageView!
    @IBOutlet weak var current1Digit: UIImageView!
    
    @IBOutlet weak var last10Digit: UIImageView!
    @IBOutlet weak var last1Digit: UIImageView!
    
    @IBOutlet weak var arrowImg: UIImageView!
    
    @IBOutlet weak var successCount: UITextField!
    @IBOutlet weak var failCount: UITextField!
    @IBOutlet weak var totalCount: UITextField!
    
    @IBOutlet weak var successRate: UITextField!
    @IBOutlet weak var failRate: UITextField!

    @IBOutlet weak var successRateWrap: UIView!
    @IBOutlet weak var failRateWrap: UIView!

    @IBOutlet weak var successGraphWrap: UIView!
    @IBOutlet weak var failGraphWrap: UIView!
    
    @IBOutlet weak var successBarWrap: UIView!
    @IBOutlet weak var successBar: UIView!
    
    @IBOutlet weak var failBarWrap: UIView!
    @IBOutlet weak var failBar: UIView!
    
    @IBOutlet var bars: [UIView]!
    
    func setScore(_ success:Int, fail:Int, last:Int) {
        self.success = success
        self.fail = fail
        self.last = last
        self.total = success + fail
    }
    
    func isDown() -> Bool { return success < last }
    
    func prepareUI() {
        successCount.text = String(success)
        failCount.text = String(fail)
        totalCount.text = String(total)
        
        setScoreImage(success, prefix:"training_score_num_light_", ten:current10Digit, one:current1Digit)
        setScoreImage(last, prefix:"training_score_num_dark_", ten:last10Digit, one:last1Digit)
        
        
    }
    
    override func viewDidLoad() {
    }

    override func viewWillAppear(_ animated: Bool) {
        initBars()
        prepareUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func onClickOK(_ sender: AnyObject) {
        view.removeFromSuperview()
    }
    
    func initBars() {
        for b in bars {
            b.roundCorner(b.height / 2)
            b.setWidth(0)
        }
    }
    
    func setScoreImage(_ num:Int, prefix:String, ten:UIImageView, one:UIImageView) {
        let t:Int = num / 10
        let o:Int = num % 10
        
        ten.image = UIImage(named:prefix+String(t))
        one.image = UIImage(named:prefix+String(o))
    }
}
