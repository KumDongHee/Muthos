//
//  SpeechRecognizingView.swift
//  muthos
//
//  Created by shining on 2016. 12. 12..
//
//

import Foundation
import SwiftyJSON
import SwiftAnimations
import AVFoundation


protocol SpeechRecognizingViewDelegate {
    func speechRecognizingViewDidClickNext(view:SpeechRecognizingView)
    func speechRecognizingViewDidClickRetry(view:SpeechRecognizingView)
    func speechRecognizingViewDidFinished(view:SpeechRecognizingView, grade:Int)
}

class SpeechRecognizingView : UIView, SpeechRecognizingDelegate {
    @IBOutlet weak var talkAnswer: UIView!
    
    @IBOutlet weak var dictationTipsArea: UIView!
    @IBOutlet weak var dictationTipsOrigin: UITextView!
    @IBOutlet weak var dictationTipsWords: UITextView!
    @IBOutlet weak var dictationTipsTranslation: UITextView!
    @IBOutlet weak var dictationTipsMemo: UITextView!
    
    @IBOutlet weak var micArea: UIView!
    @IBOutlet weak var resultArea: UIView!

    @IBOutlet weak var pulse: UIView!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var btnTalkAnswer: UIButton!
    
    @IBOutlet weak var btnRetry: UIButton!
    
    @IBOutlet weak var btnNext: UIButton!
    @IBOutlet weak var retryBedgeArea: UIView!
    
    @IBOutlet weak var retryCountLbl: UILabel!
    @IBOutlet weak var scoreImage: UIImageView!
    
    @IBOutlet weak var answerArea: UIView!
    @IBOutlet weak var answerBallon: UIView!
    
    @IBOutlet weak var recognizedBack: UIView!
    @IBOutlet weak var answerText: UITextView!
    @IBOutlet weak var recognizedText: UITextView!
    @IBOutlet weak var answerTriangle: TriangleView!
    
    @IBOutlet weak var lightImage: UIImageView!
    
    var micOverLayer:CALayer = CALayer()
    var isPractice:Bool = false
    var delegate:SpeechRecognizingViewDelegate? = nil
    
    func prepareAnimationComponents() {
        micOverLayer.frame = CGRect(x: 0, y: 0, width: micButton.frame.size.width, height: micButton.frame.size.height)
        micOverLayer.backgroundColor = UIColor.yellow.cgColor
        micOverLayer.opacity = 0.0
        micOverLayer.cornerRadius = micOverLayer.frame.width/2
        micButton.layer.addSublayer(micOverLayer)
        
    }

    @IBAction func onClickTalkAnswer(_ sender: AnyObject) {
        print("onClickTalkAnswer")
    }
    
    @IBAction func onRecognizing(_ sender: AnyObject) {
        print("onRecognizing")
        let controller = ApplicationContext.sharedInstance.sharedBookController
        
        if self.recognizing == true {
            self.micButton.isEnabled = false
            DispatchQueue.main.asyncAfter(deadline: (DispatchTime.now() + 1)) {
                controller.recognizer!.stopRecognizing()
            }
            return
        }
        
        animate { self.micButton.alpha = 0.5 }
            .withDuration(0.3).withOptions(.curveEaseOut).completion { (finish) -> Void in }
        
        controller.recognizer!.setDelegate(self)
        DispatchQueue.main.async {
            _ = controller.recognizer!.recognize(callback:{() -> Bool in
                self.showResultArea(self.model!["text"].stringValue, desc: controller.recognizer!.recognized)
                return true
            })
            self.setRecoginzingStatus(true)
            animate { self.micButton.alpha = 1.0 }
                .withDuration(0.3).withOptions(.curveEaseOut).completion { (finish) -> Void in }
        }
    }
    
    func setRecoginzingStatus(_ status:Bool) {
        self.recognizing = status
        var image:String?
        if status {
            image = "control_btn_speak_default"
        }
        else {
            image = "control_btn_speak_record"
        }
        
        micButton.setBackgroundImage(UIImage(named:image!), for: UIControlState())
    }
    
    @IBAction func onRetry(_ sender: Any) {
        print("onRetry")
        if self.isPractice {
            initUI()
            self.prepareAnimationComponents()
        }
    }
    
    @IBAction func onNext(_ sender: Any) {
        print("onNext")
    }
    
    var model:JSON? {
        didSet {
        }
    }
    
    var recognizing:Bool = false
    var answerFrame:CGRect?
    var recognizedFrame:CGRect?
    
    func initUI() {
        resultArea.isHidden = true
        dictationTipsArea.isHidden = true
        micArea.isHidden = false
        talkAnswer.isHidden = false
        btnTalkAnswer.isHidden = false
        answerFrame = answerText.frame
        recognizedFrame = recognizedText.frame
        micButton.isEnabled = true
        micButton.alpha = 1

    }
    
    func startListening(animation:Bool) {
        if animation {
            //마이크 떠오르는 애니메이션
            micButton.transform = CGAffineTransform(translationX: 0, y: 30)
            micButton.layer.opacity = 0
            
            animate {
                self.micButton.transform = CGAffineTransform.identity
                self.micButton.layer.opacity = 1
                }.withDuration(0.3)
                .withOptions(.curveEaseOut)
                .completion { (finish) -> Void in
                    if finish {
                        
                    }
            }
        }
        else {
            micButton.layer.opacity = 1
        }
    }
    
    func display(on:UIView, model:JSON) {
        print(model)
        initUI()
        
        self.model = model
        
        self.removeFromSuperview()
        
        self.frame = on.bounds
        on.addSubview(self)
        
        self.layoutSubviews()

        self.prepareAnimationComponents()
        _ = pulse.circle()
    }
    
    // MARK: - showResultArea
    func showResultArea(_ orig:String, desc:String) {
        let images:[String] = ["control_result_30", "control_result_50", "control_result_70", "control_result_90", "control_result_100"]
        let effects:[SOUND_CODE] = [.bad, .notBad, .good, .excellent, .perfect]
        let json:JSON = BookController.evaluateSentence(orig, desc: desc)
        var grade:Int = max(json["grade"].intValue, 1) as Int
        
        //animation
        self.renderTalkAnswer(self.answerText, string:json["orig"].stringValue)
        self.renderTalkAnswer(self.recognizedText, string:json["desc"].stringValue)
        self.alignTalkAnswers()
        
        /*
         1. micButton 사이즈 줄이면서 색깔 노란색으로 바꿔줌
         2. 아래로 내림
         3. 위로 올림
         4. 최소화된 상태의 result area와 변경 (차후)
         5. result area 키워줌 (차후)
         6. score image 보여줌
         7. retry, next 보여줌 (6,7이 약간의 시간차 있으나 아직 구현안됨)
         8. complete block 실행
         */
        let moveDown = CGAffineTransform(translationX: 0, y: 10)
        let scaleDown = CGAffineTransform(scaleX: 0.15, y: 0.15)
        let micCenter = micButton.center
        
        scoreImage.image = UIImage(named: images[grade-1])
        scoreImage.layer.opacity = 0
        lightImage.layer.opacity = 0
        retryBedgeArea.layer.opacity = 0
        btnNext.layer.opacity = 0
        btnRetry.layer.opacity = 0
        answerText.layer.opacity = 0
        recognizedText.layer.opacity = 0
        scoreImage.transform = moveDown
        btnNext.transform = moveDown
        btnRetry.transform = moveDown
        answerArea.transform = scaleDown
        retryBedgeArea.transform = scaleDown
        
        answerTriangle.point = .bottomLeft
        answerTriangle.setNeedsDisplay()
        
        animate {
            self.pulse.isHidden = true
            self.micButton.transform = scaleDown
            self.micOverLayer.opacity = 1.0
            }.withOptions(.curveEaseOut).withDuration(0.2).thenAnimate({_ -> Void in
                self.micButton.center = CGPoint(x: micCenter.x, y: micCenter.y+10)
            }).withDuration(0.11).withOptions(.curveEaseOut).thenAnimate({_ -> Void in
                  self.micButton.center = CGPoint(x: micCenter.x, y: self.answerArea.frame.midY + self.micButton.frame.size.height/2.0)
                self.answerArea.center = self.micButton.center
                
                self.micButton.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                self.resultArea.isHidden = false
                self.answerArea.isHidden = true
            }).withDuration(0.33).withOptions(.curveEaseIn).thenAnimate({_ -> Void in
                self.answerArea.isHidden = false
                self.answerArea.transform = CGAffineTransform.identity
                self.lightImage.layer.opacity = 1
            }).withDuration(0.1).withOptions(.curveEaseOut).thenAnimate({_ -> Void in
                self.answerText.layer.opacity = 1
                self.recognizedText.layer.opacity = 1
            }).withDuration(0.3).withOptions(.curveEaseOut).thenAnimate({_ -> Void in
                self.scoreImage.transform = CGAffineTransform.identity
                self.scoreImage.layer.opacity = 1
                ApplicationContext.playEffect(code: effects[grade-1])
            }).withDuration(0.3).withOptions(.curveEaseOut).thenAnimate({_ -> Void in
                self.micButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                if !self.isPractice {
                    self.btnNext.layer.opacity = 1
                    self.btnNext.transform = CGAffineTransform.identity
                }
                self.btnRetry.layer.opacity = 1
                self.btnRetry.transform = CGAffineTransform.identity
            }).withDuration(0.3).withOptions(.curveEaseOut).thenAnimate({_ -> Void in
                if !self.isPractice {
                    self.retryBedgeArea.layer.opacity = 1
                    self.retryBedgeArea.transform = CGAffineTransform.identity
                }
            }).withDuration(0.1).withOptions(.curveEaseOut).completion { (finish) -> Void in
                if finish {
                    self.micArea.isHidden = true
                    self.micButton.transform = CGAffineTransform.identity
                    self.micOverLayer.opacity = 0.0
                    self.micButton.center = micCenter
                    if grade == 0 {
                        grade = 1
                    }
                    self.setRecoginzingStatus(false)
                    self.playResultAreaAnimation()
                }
        }
        
        if !self.isPractice {
            ApplicationContext.sharedInstance.userViewModel.appendExp(1,memo:"speech")
        } else {
        }
        
        if let delegate = self.delegate {
            delegate.speechRecognizingViewDidFinished(view: self, grade: grade)
        }
    }
    
    func playResultAreaAnimation() {
        Async.series(
            [
                {(nxt:Async.callbackFunc) -> Void in
                    UIView.animate(withDuration: 1.0, animations: {() -> Void in
                    })
                }
            ],
            callback:{() -> Bool in
                return true
        }
        )
    }
    
    let PADDING_WIDTH:CGFloat = 8

    func renderTalkAnswer(_ view:UITextView, string:String) {
        let ORIGIN_BOUNDS:CGRect = CGRect(x: 0,y: 0,width: MainCont.scaledSize(300) - PADDING_WIDTH * 2,height: 32)
        
        let prefix:String = "<div style='margin-left:auto;display:-webkit-box;-webkit-box-align:center;-webkit-box-pack:center;width:100%;text-align:center;font-family:Apple SD Gothic Neo;font-weight:400;font-size:18px;'>"
        let suffix:String = "</div>"
        
        view.bounds = ORIGIN_BOUNDS
        
        view.textAlignment = NSTextAlignment.center
        view.isEditable = false
        view.layer.masksToBounds = true
        let html:String = prefix + string + suffix
        do {
            let style = NSMutableParagraphStyle()
            style.alignment = NSTextAlignment.center
            let str = try NSMutableAttributedString(data: html.data(using: String.Encoding.unicode, allowLossyConversion: true)!, options: [ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSParagraphStyleAttributeName:style], documentAttributes: nil)
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineSpacing = -2.0
            str.addAttribute(NSParagraphStyleAttributeName, value:paraStyle, range:NSMakeRange(0, str.length))
            
            view.attributedText = str
        } catch {
            print(error)
        }
        view.sizeToFit()
    }
    
    func adjustViewOnBottom(_ view:UIView, bottom:CGFloat, rect:CGRect) {
        view.frame = CGRect(x: view.frame.origin.x, y: rect.size.height-bottom-view.frame.size.height, width: view.frame.size.width, height: view.frame.size.height)
    }
    
    func alignCenterHorizontal(_ view:UIView, on:CGRect) {
        let frame:CGRect = view.frame
        let center:CGFloat = on.midX
        
        view.frame = CGRect(x: center - frame.size.width/2, y: frame.origin.y, width: frame.size.width, height: frame.size.height)
    }

    func alignTalkAnswers() {
        let Y_MOVE:CGFloat = 0
        let X_MOVE:CGFloat = 3
        let BOTTOM_MARGIN:CGFloat = 1
        let PADDING_TRIANGLE:CGFloat = 20
        let bottomGuides:[CGFloat] = [103, 97, 81, 65]
        let wordsPerLine:Int = 30
        self.answerArea.frame = CGRect(x: 0,y: 0,width: max(answerText.frame.size.width, recognizedText.frame.size.width) + PADDING_WIDTH * 2, height: self.answerText.frame.size.height + self.recognizedText.frame.size.height + self.answerTriangle.height + BOTTOM_MARGIN)
        
        self.alignCenterHorizontal(self.answerArea, on:self.resultArea.frame)
        self.adjustViewOnBottom(self.answerArea, bottom: bottomGuides[NSInteger(recognizedText.text.lengthOfBytes(using: String.Encoding.utf8) / wordsPerLine)], rect:resultArea.frame)
        
        self.answerTriangle.frame = CGRect(x: self.answerArea.width - PADDING_TRIANGLE, y: self.answerArea.height-answerTriangle.height, width: answerTriangle.width, height: answerTriangle.height)
        
        self.answerBallon.layer.cornerRadius = 3
        
        let height:CGFloat = answerText.height
        
        self.answerBallon.frame = CGRect(x: 0,y: 0,width: self.answerArea.width, height: answerText.height + recognizedText.height + BOTTOM_MARGIN)
        self.answerText.frame = CGRect(x: PADDING_WIDTH+X_MOVE,y: 0, width: self.answerText.width, height: height - Y_MOVE)
        self.recognizedText.frame = CGRect(x: PADDING_WIDTH+X_MOVE, y: height+BOTTOM_MARGIN, width: self.recognizedText.width, height: recognizedText.height)
        self.recognizedBack.frame = CGRect(x: 0, y: height, width: self.answerArea.width , height: recognizedText.height + BOTTOM_MARGIN)
        
        self.resultArea.layoutSubviews()
    }
    
    var recentlyMicLevel:Float = 0
    // MARK: - SpeechRecognizingDelegate
    func speechRecognizing(_ speechRecognizing:SpeechRecognizing, listening:String, level:Float) {
        self.recentlyMicLevel = level
        self.performSelector(onMainThread: #selector(SpeechRecognizingView.doPulse), with: nil, waitUntilDone: false);
    }
    
    func doPulse() {
        let level = self.recentlyMicLevel
        let LEVEL_MAX:Float = 2
        let CIRCLE_MAX:Float = 125
        let CIRCLE_MIN:Float = 64
        
        let rate = min(abs(level), LEVEL_MAX) / LEVEL_MAX
        
        let size = CGFloat((CIRCLE_MAX - CIRCLE_MIN) * rate + CIRCLE_MIN)
        
        print(level, rate, size)
        
        pulse.setWidth(size)
        pulse.setHeight(size)
        pulse.center = micButton.center
        _ = pulse.circle()
        
        pulse.isHidden = false
    }
}
