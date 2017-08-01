//
//  SituationCont.swift
//  Muthos
//
//  Created by Youngjune Kwon on 2016. 1. 16..
//
//

import Foundation
import UIKit
import AVFoundation
import QuartzCore
import SwiftyJSON
import SwiftAnimations
import iCarousel

class SituationCont : DefaultCont, UITextFieldDelegate, iCarouselDataSource, iCarouselDelegate, BallonViewDelegate, SpeechRecognizingDelegate {
    var controller:BookController?
    var currentAnswer:String?
    var currentSpeechModel:JSON?
    var answerFrame:CGRect?
    var recognizedFrame:CGRect?
    var recognizing:Bool = false
    var aUnit:AudioUnit?
    var micOverLayer:CALayer = CALayer()
    var model:JSON?
    var videoCallback:Async.callbackFunc?
    var players : [AVPlayer] = []
    var playerLayers : [AVPlayerLayer] = []
    var currentPlayerIndex : Int = 0
    var looping:Bool = false
    var progressing:Bool = false
    var audioPlayer:AVAsyncPlayer = AVAsyncPlayer()
    var currentSet:String?
    var currentRetry:Int = 0
    var currentWebviewIdx:Int = 0
    var currentPivotIdx:Int = 0
    var currentSequence:Int = 0 {
        didSet {
            var idx:Int = 0
            for p:Pivot in pivots {
                if p.index >= currentSequence {
                    break
                }
                idx += 1
            }
            currentPivotIdx = idx
            pivotsCarousel!.reloadData()
            pivotsCarousel!.scrollToItem(at: currentPivotIdx, animated:true)
        }
    }
    var htmlCached:Bool = false
    var currentQuestion:JSON?
    var currentSpeechVoice:URL?
    var holdNextSequence:Bool = false
    var currentBallonView:BallonView?
    var currentDictationModel:DictationModel?
    var currentNarration:JSON?
    var playMode:String? = ""
    var listenPaused:Bool = false
    var pivots:[Pivot] = []
    var videoLoop:VideoLoop?
    
    let quotes:NSMutableArray = NSMutableArray()
    let narrations:NSMutableArray = NSMutableArray()
    var popOver:DialogPopOverCont = BookController.loadViewController("Situation", viewcontroller: "DialogPopOverCont") as! DialogPopOverCont
    
    @IBOutlet weak var btnNext: UIButton!
    @IBOutlet weak var btnRetry: UIButton!
    @IBOutlet weak var btnNextSequence: UIButton!
    @IBOutlet weak var resultArea: UIView!
    @IBOutlet weak var micArea: UIView!
    @IBOutlet weak var talkAnswer: UIView!
    @IBOutlet weak var answerText: UITextView!
    @IBOutlet weak var recognizedText: UITextView!
    @IBOutlet weak var recognizedBack: UIView!
    @IBOutlet weak var scene: UIView!
    @IBOutlet weak var scoreImage: UIImageView!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var lightImage: UIImageView!
    @IBOutlet weak var answerArea: UIView!
    @IBOutlet weak var retryBedgeArea: UIView!
    @IBOutlet weak var retryCountLbl: UILabel!
    @IBOutlet var webviews: [UIWebView]!
    @IBOutlet var screens: [UIView]!
    @IBOutlet weak var answerBallon: UIView!
    @IBOutlet weak var imageScene: UIImageView!
    @IBOutlet weak var answerTriangle: TriangleView!
    @IBOutlet weak var dictationText: UITextField!
    @IBOutlet weak var dictationLabelArea: UIView!
    @IBOutlet weak var dictationLabel: UILabel!
    @IBOutlet weak var dictationLabelBackground: UIView!
    
    @IBOutlet weak var dictationTipsArea: UIView!
    @IBOutlet weak var dictationTipsOrigin: UITextView!
    @IBOutlet weak var dictationTipsWords: UITextView!
    @IBOutlet weak var dictationTipsTranslation: UITextView!
    @IBOutlet weak var dictationTipsMemo: UITextView!
    
    @IBOutlet weak var listenArea: UIView!
    @IBOutlet weak var btnPauseListen: UIButton!
    @IBOutlet weak var pivotsCarousel: iCarousel!
    @IBOutlet weak var bgTopNarration: UIImageView!

    @IBOutlet weak var pulse: UIView!
    @IBOutlet weak var btnReplay: UIButton!

    @IBAction func onTogglePauseListen(_ sender: AnyObject) {
        procListenPaused(!listenPaused)
    }
    
    deinit {
        print("deinit, SituationCont")
    }
    
    class DictationModel {
        var model:JSON
        var textView:UITextView?
        init(_ model:JSON, textView:UITextView?) {
            self.model = model
            self.textView = textView
        }
    }
    
    func procListenPaused(_ pause:Bool) {
        listenPaused = pause
        btnPauseListen.isHidden = pause
        btnPauseListen.setImage(UIImage(named:listenPaused ? "control_btn_play" : "control_btn_pause"), for: UIControlState())
        let l:[NSLayoutConstraint] = listenArea.constraints.filter({$0.firstAttribute == .bottom}).filter({$0.secondItem is UIButton})
        l[0].constant = listenPaused ? 109 : 23

        if listenPaused {showPivotsCarousel(); controller!.stopVoice()}
        else {hidePivotsCarousel()}
    }
    
    @IBAction func onNext(_ sender: AnyObject) {
        self.btnNextSequence.isHidden = true
        
        if model?["category"].string == "video" || model?["category"].string == "video-streaming" {
            self.goNextSet()
        }
        else if model?["category"].string == "picture" {
            self.clearQuotes()
            self.clearListening()
            if self.holdNextSequence == true {
                self.holdNextSequence = false
            }
            else {
                resetBgNarration({() -> Bool in
                    self.renderNextSequence()
                    return true
                })
            }
        }
    }
    
    @IBAction func onRetry(_ sender: AnyObject) {
        if currentRetry <= 0 {
            return
        }
        
        currentRetry -= 1
        ApplicationContext.sharedInstance.userViewModel.consumeRetry(1, memo: "talk")
        
        self.clearListening()
        if model?["category"].string == "video" || model?["category"].string == "video-streaming" {
            self.playCurrentQuestion()
        }
        else if model?["category"].string == "picture" {
            self.renderCurrentSequence()
        }
    }
    
    @IBAction func onClickTalkAnswer(_ sender: AnyObject) {
        if self.micArea.isHidden == false{
            let speechRecognizer = SpeechFrameworkRecognizer.instance()
            if !speechRecognizer.getOnRecognize() {
                // 일반 재생
                self.replayCurrentVoice()
            }
            else {
                ///// TODO : 무음 재생
            }
        }
    }
    
    @IBAction func onClickReplay(_ sender: Any) {
        let speechRecognizer = SpeechFrameworkRecognizer.instance()
        if !speechRecognizer.getOnRecognize() {
            // 일반 재생
            self.replayCurrentVoice()
        }
        else {
            ///// TODO : 무음 재생
        }
    }
    
    @IBAction func onRecognizing(_ sender: AnyObject) {
        if self.recognizing == true {
            self.micButton.isEnabled = false
            DispatchQueue.main.asyncAfter(deadline: (DispatchTime.now() + 1)) {
                self.controller!.recognizer!.stopRecognizing()
            }
            return
        }
        
        animate { self.micButton.alpha = 0.5 }
            .withDuration(0.3).withOptions(.curveEaseOut).completion { (finish) -> Void in }
        
        audioPlayer.doVolumeFade(callback:{() -> Bool in
            return true
        })

        self.controller!.recognizer!.setDelegate(self)
        DispatchQueue.main.async {
            _ = self.controller!.recognizer!.recognize(withAnswer:self.currentAnswer!, callback:{() -> Bool in
                self.showResultArea(self.currentAnswer!, desc: self.controller!.recognizer!.recognized)
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
    
    func showDictationResult(_ orig:String, desc:String) {
        print(dictationLabelArea.frame)
        dictationText.isHidden = true
        dictationLabelArea.isHidden = true
        
        let images:[String] = ["control_result_fail", "control_result_success"]
        let lightImages:[String] = ["control_result_light_violet", "control_result_light_yellow"]
        let effects:[SOUND_CODE] = [.fail, .success]
        let json:JSON = BookController.evaluateSentence(orig, desc: desc)
        
        talkAnswer.isHidden = false
        resultArea.isHidden = false
        
        answerArea.isHidden = true
        micArea.isHidden = true
        
        retryBedgeArea.isHidden = true
        btnRetry.isHidden = true
        
        let grade:Int = json["grade"].intValue == 5 ? 1 : 0
        scoreImage.image = UIImage(named: images[grade])
        lightImage.image = UIImage(named:lightImages[grade])

        ApplicationContext.playEffect(code: effects[grade])
        
        self.controller!.writeBonus(orig, grade: grade)
        
        if self.currentBallonView != nil {
            self.currentBallonView?.showDictationResult()
            showDictationTips(self.currentBallonView!.quote!, result:json)
        } else if let tv = self.currentDictationModel?.textView {
            let model = self.currentDictationModel?.model
            let text:String = model!["text"].string!
            var fontSize:Int = 20
            if let fs:Int = model?["font-size"].intValue {
                if fs > 0 { fontSize = fs }
            }
            if let dictations:String = model?["dictation"].string {
                var html:String = BookController.getDictationResultOf(text, dictations: dictations)
                html = "<span style='color:white;font-size:"+String(fontSize)+"'>" + html + "</span>"
                BallonView.setHtmlText(html, on: tv)
                tv.sizeToFit()
            }
            
            BallonView.showDictationResultOn(textView:tv, model:(self.currentDictationModel?.model)!, white:true, fontSize:fontSize)
            showDictationTips(model!, result:json);
        }
        
        ApplicationContext.sharedInstance.userViewModel.appendExp(1, memo:"dictation")
        
        forceRetainDictationLevelArea()
        
        reserveConsumeSequence(1)
    }
    
    func forceRetainDictationLevelArea() {
        dictationLabelArea.isHidden = true
        dictationLabelArea.removeFromSuperview()
        self.view.addSubview(dictationLabelArea)
    }
    
    func showDictationTips(_ model:JSON, result:JSON) {
        let dictations:String = model["dictation"].string!
        let correct:Bool = result["grade"].intValue == 5

        let tv:UITextView = UITextView()
        tv.frame = dictationTipsOrigin.bounds
        tv.setHeight(1000)

        var html:String = BookController.getDictationResultOf(model["text"].string!,
                                                              dictations: dictations,
                                                              correct:correct, desc:result["desc"].string!)
        html = "<span style='color:white;font-size:18px'>" + html + "</span>"
        
        BallonView.setHtmlText(html, on: tv)
        BallonView.setHtmlText(html, on: dictationTipsOrigin)
        
        tv.sizeToFit()
        
        let con = dictationTipsOrigin.constraints[0]
        con.constant = tv.height

        dictationTipsWords.text = self.currentAnswer
        
        dictationTipsTranslation.text = ""
        dictationTipsMemo.text = ""
        
        if  model["dictation-translation"].error == nil {
            dictationTipsTranslation.text = model["dictation-translation"].string
        }
        
        if model["dictation-memo"].error == nil {
            var memo:String = ""
            for any in model["dictation-memo"].array! {
                memo += any.string!
                memo += "\n"
            }
            dictationTipsMemo.text = memo
        }
        dictationTipsArea.isHidden = false
    }
    
    func showResultArea(_ orig:String, desc:String) {
        audioPlayer.resumeLooping()
        
        let sequence:JSON = controller!.selectedSequence()
        var seqJson:JSON = sequence[currentSequence]["params"]
        
        let images:[String] = ["control_result_30", "control_result_50", "control_result_70", "control_result_90", "control_result_100"]
        let effects:[SOUND_CODE] = [.bad, .notBad, .good, .excellent, .perfect]
        let json:JSON = BookController.evaluateSentence(orig, desc: desc, flexibility:seqJson["flexibility"])
        var grade:Int = max(json["grade"].intValue, 1) as Int
        
        self.lightImage.image = UIImage(named:"control_result_light_yellow")
        
        self.controller!.writeScore(self.currentSpeechModel!["voice"].string!, grade: grade)
        
        self.retryCountLbl.text = String(currentRetry)
        
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
        
        let quote:BallonView = BallonView()
        seqJson["text"].stringValue = orig.characters.count > desc.characters.count ? orig : desc
        quote.setModel(seqJson, controller:controller!)
        /* 말풍선 꼬리 모양 / 위치 보정 */
        answerTriangle.point = quote.triangle.point
        answerTriangle.baseline = quote.triangle.baseline
        print(answerTriangle.frame, quote.triangle.frame)
        let frame:CGRect = answerTriangle.frame
        answerTriangle.frame = quote.triangle.frame
        if answerTriangle.point == .bottomRight || answerTriangle.point == .bottomLeft {
            answerTriangle.setY(frame.origin.y)
        }
        if answerTriangle.point == .leftUp || answerTriangle.point == .leftDown
           || answerTriangle.point == .rightUp || answerTriangle.point == .rightDown
        {
            answerTriangle.setY(answerTriangle.y + recognizedBack.y)
        }
        answerTriangle.setNeedsDisplay()
        
        animate {
            self.pulse.isHidden = true
            self.micButton.transform = scaleDown
            self.micOverLayer.opacity = 1.0
            }.withOptions(.curveEaseOut).withDuration(0.2).thenAnimate({_ -> Void in
                self.micButton.center = CGPoint(x: micCenter.x, y: micCenter.y+10)
            }).withDuration(0.11).withOptions(.curveEaseOut).thenAnimate({_ -> Void in
//                self.micButton.center = CGPoint(x: micCenter.x, y: self.answerArea.frame.midY + self.micButton.frame.size.height/2.0)
                self.micButton.center = quote.center
                self.answerArea.center = self.micButton.center
                
                self.micButton.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                self.resultArea.isHidden = false
                self.answerArea.isHidden = true
            }).withDuration(0.33).withOptions(.curveEaseIn).thenAnimate({_ -> Void in
                self.answerArea.isHidden = false
                self.answerArea.transform = CGAffineTransform.identity
                self.answerArea.transform = CGAffineTransform(scaleX: MainCont.SIZE_RATIO, y: MainCont.SIZE_RATIO)
                self.answerArea.layer.shadowColor = UIColor.black.cgColor
                self.answerArea.layer.shadowOpacity = 0.4
                self.answerArea.layer.shadowRadius = 2
                self.answerArea.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
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
                self.btnNext.layer.opacity = 1
                self.btnRetry.layer.opacity = 1
                self.btnNext.transform = CGAffineTransform.identity
                self.btnRetry.transform = CGAffineTransform.identity
            }).withDuration(0.3).withOptions(.curveEaseOut).thenAnimate({_ -> Void in
                self.retryBedgeArea.layer.opacity = 1
                self.retryBedgeArea.transform = CGAffineTransform.identity
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
        
        ApplicationContext.sharedInstance.userViewModel.appendExp(1,memo:"speech")
    }
    
    func setSizeWithFixedCenter(_ view:UIView, size:CGSize) {
        let frame = view.frame
        let diff:CGPoint = CGPoint(x: (size.width - frame.size.width) / 2, y: (size.height - frame.size.height) / 2)
        view.frame = CGRect(x: frame.origin.x + diff.x, y: frame.origin.y + diff.y, width: size.width, height: size.height)
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
    
    func adjustViewOnBottom(_ view:UIView, bottom:CGFloat, rect:CGRect) {
        view.frame = CGRect(x: view.frame.origin.x, y: rect.size.height-bottom-view.frame.size.height, width: view.frame.size.width, height: view.frame.size.height)
    }
    
    func alignCenterHorizontal(_ view:UIView, on:CGRect) {
        let frame:CGRect = view.frame
        let center:CGFloat = on.midX
        
        view.frame = CGRect(x: center - frame.size.width/2, y: frame.origin.y, width: frame.size.width, height: frame.size.height)
    }

    let PADDING_WIDTH:CGFloat = 8

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
        self.answerBallon.layer.shadowColor = UIColor.black.cgColor
        self.answerBallon.layer.shadowOpacity = 0.4
        self.answerBallon.layer.shadowRadius = 2
        self.answerBallon.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        
        let height:CGFloat = answerText.height
        
        self.answerBallon.frame = CGRect(x: 0,y: 0,width: self.answerArea.width, height: answerText.height + recognizedText.height + BOTTOM_MARGIN)
        self.answerText.frame = CGRect(x: PADDING_WIDTH+X_MOVE,y: 0, width: self.answerText.width, height: height - Y_MOVE)
        self.recognizedText.frame = CGRect(x: PADDING_WIDTH+X_MOVE, y: height+BOTTOM_MARGIN, width: self.recognizedText.width, height: recognizedText.height)
        self.recognizedBack.frame = CGRect(x: 0, y: height, width: self.answerArea.width , height: recognizedText.height + BOTTOM_MARGIN)
        
        self.resultArea.layoutSubviews()
    }
    
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
    
    func goNextSet() {
        if self.assignNextSet() {
            self.renderNextSet()
        }
        else {
            self.showScore()
        }
    }
    
    func renderNextSet() {
        self.clearListening()
        self.switchPlayer()
        self.refresh()
    }
    
    func initUI() {
        self.answerArea.translatesAutoresizingMaskIntoConstraints = true
        self.answerBallon.translatesAutoresizingMaskIntoConstraints = true
        self.answerText.translatesAutoresizingMaskIntoConstraints = true
        self.recognizedText.translatesAutoresizingMaskIntoConstraints = true
        self.recognizedBack.translatesAutoresizingMaskIntoConstraints = true
        self.answerTriangle.translatesAutoresizingMaskIntoConstraints = true
    }
    
    func initRetryCount() {
        currentRetry = (ApplicationContext.sharedInstance.userViewModel.currentUserObject()?.getRetry())!
    }
    
    func clearListening() {
        self.currentAnswer = ""
        answerText.text = ""
        recognizedText.text = ""
        resultArea.isHidden = true
        micArea.isHidden = false
        talkAnswer.isHidden = true
        dictationTipsArea.isHidden = true
        
        retryBedgeArea.isHidden = false
        btnRetry.isHidden = false
        
        if let f = self.answerFrame {
            answerText.frame = f
        }
        if let f = self.recognizedFrame {
            recognizedText.frame = f
        }
    }
    
    func startListening(_ model:JSON) {
        self.currentSpeechModel = model
        self.currentAnswer = model["text"].string!
        resultArea.isHidden = true
        micArea.isHidden = false
        talkAnswer.isHidden = false
        answerFrame = answerText.frame
        recognizedFrame = recognizedText.frame
        
        //마이크 떠오르는 애니메이션
        micButton.transform = CGAffineTransform(translationX: 0, y: 30)
        micButton.layer.opacity = 0
        micButton.isEnabled = true
        
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.controller = ApplicationContext.sharedInstance.sharedBookController
        self.popOver.controller = self.controller

        self.dictationText.autocorrectionType = UITextAutocorrectionType.no
        
        answerArea.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SituationCont.onTouchAnswerArea(_:))))

        initSinglePlayer()
        initSinglePlayer()

        videoLoop = VideoLoop(cont:self)
    }
    
    override func viewDidLayoutSubviews() {
        self.initUI()
    }
    
    func hideAllScreens() {
        for v in screens {
            v.isHidden = true
        }
    }
    
    func prepareAnimationComponents() {
        micOverLayer.frame = CGRect(x: 0, y: 0, width: micButton.frame.size.width, height: micButton.frame.size.height)
        micOverLayer.backgroundColor = UIColor.yellow.cgColor
        micOverLayer.opacity = 0.0
        micOverLayer.cornerRadius = micOverLayer.frame.width/2
        micButton.layer.addSublayer(micOverLayer)
        
    }
    
    func doTest() {
        micButton.alpha = 1.0
        let model:JSON = JSON.parse("{\"text\":\"\", \"voice\":\"1\"}")
        startListening(model)
        
        self.perform(#selector(SituationCont.doTest01), with: nil, afterDelay: 0.5)
    }
    
    func doTest01() {
        self.showResultArea("What's wrong, baby?", desc: "What's wrong")
    }
    
    var flagReserveStart:Bool = false
    var onceWorked:Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isTranslucent = true

        navigationController?.navigationBar.hideLine()
        let index:String = controller!.model!["sets"][controller!.selectedIdx!]["index"].stringValue
        let title:String = "Set " + index
        (self.navigationItem.titleView?.subviews[0] as! UILabel).text = title

        if flagReserveStart {
            flagReserveStart = false
            start()
        }
    }

    func reserveStart() {
        flagReserveStart = true
    }
    
    func start() {
        progressing = true
        
        controller!.hideScore()
        clearQuotes()
        clearListening()
        initRetryCount()
        hideAllScreens()
        model = self.controller!.model
        initPivots()
        initPivotsCarousel()
        
        scene.isHidden = false
        selectPlayerAtIndex(0)
        _ = videoLoop!.start()
        
        currentSequence = 0
        
        procListenPaused(false)
        
        Async.series([
            {(nxt:@escaping Async.callbackFunc) -> Void in
                (self.controller?.downloadResource(onStarted: {() -> Bool in
                    return nxt()
                }))!
            },
            {(nxt:@escaping Async.callbackFunc) -> Void in
                if self.model?["category"].string == "video" || self.model?["category"].string == "video-streaming" {
                    _ = self.assignNextSet()
                    self.refresh()
                }
                else if self.model?["category"].string == "picture" {
                    if "listen" == self.playMode! {
                        self.renderCurrentSequence()
                    }
                    else {
                        self.restoreLastSequence()
                    }
                }
                _ = nxt()
            }
            ], callback:{()->Bool in return true });
        
        self.listenArea.isHidden = "talk" == playMode
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.prepareAnimationComponents()
        if onceWorked == false {
            onceWorked = true
            dictationLabelBackground.layer.cornerRadius = 4
            _ = dictationLabelBackground.borderWith(UIColor(white:0, alpha:0.15), width: 1)
            _ = pulse.circle()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view!.endEditing(true)
        self.showDictationResult(self.currentAnswer!, desc:self.dictationText.text!)
        self.dictationText.text = ""
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    func restoreLastSequence() {
        guard let controller = controller else { return }
        
        let bookId:String = (controller.book?._id)!
        let setIndex:String = controller.model!["sets"][controller.selectedIdx!]["index"].stringValue
        let lastSequence:Int = ApplicationContext.sharedInstance.userViewModel.lastSequence(bookId:bookId,
                                                  setIndex: setIndex,
                                                  playMode:self.playMode!, bookMode:controller.bookMode)

        var pivotIndex:Int = 0
        for p:Pivot in pivots {
            if p.index >= lastSequence {
                break
            }
            pivotIndex += 1
        }
        
        let sequence:JSON = controller.selectedSequence()
        
        if sequence[lastSequence]["type"].stringValue == "next" { pivotIndex -= 1 }
        
        if pivotIndex > 0 {
            self.listenPaused = true
            restoreBackgroundOnPivotIndex(pivotIndex)

            let refreshAlert = UIAlertController(title: "알림", message: "이전 학습을 이어서 하시겠습니까.", preferredStyle: UIAlertControllerStyle.alert)
            
            refreshAlert.addAction(UIAlertAction(title: "이어서 하기", style: .cancel, handler: { (action: UIAlertAction!) in
                self.renderCurrentSequence()
            }))
            
            refreshAlert.addAction(UIAlertAction(title: "처음부터 하기", style: .default, handler: { (action: UIAlertAction!) in
                self.currentSequence = 0
                self.renderCurrentSequence()
            }))
            
            present(refreshAlert, animated: true, completion: nil)
        }
        else {
            renderCurrentSequence()
        }
    }
    
    func saveLastSequence() {
        guard let controller = controller else { return }

        let bookId:String = (controller.book?._id)!
        let setIndex:String = controller.model!["sets"][controller.selectedIdx!]["index"].stringValue
        var lastSequence:Int = currentSequence == 0 ? 0 : currentSequence
        
        if resultArea.isHidden == false {
            lastSequence += 1
        }
        
        ApplicationContext.sharedInstance.userViewModel
            .updateLastSequence(bookId:bookId, setIndex: setIndex,
                                playMode:self.playMode!, sequence: lastSequence, bookMode:controller.bookMode)
    }
    
    func finaly() {
        
        view!.endEditing(true)
        if dictationLabelArea.isHidden == false {
            dictationLabelArea.isHidden = true
            forceRetainDictationLevelArea()
        }
        dictationText.isHidden = true
        dictationText.text = ""
        
        NotificationCenter.default.removeObserver(self)
        controller?.stopVoice()
        progressing = false
        looping = false
        pauseAllPlayers()
        videoLoop!.stop()
        clearQuotes()
        clearNarrationsSync()
        audioPlayer.stop()
        controller!.recognizer!.setDelegate(nil)
        saveLastSequence()
    }
    
    func pauseAllPlayers() {
        for p in players {
            p.pause()
        }
    }
    
    override func touchLeftButton() {
        super.touchLeftButton()
        self.close()
    }
    
    func showScore() {
        self.finaly()
        
        controller?.showScoreOn(self.view, onClose:{() -> Bool in
            self.navigationController!.popViewController(animated: true)
            return true
        })
    }
    
    func close() {
        self.finaly()
        self.navigationController!.popViewController(animated: true)
        self.dismiss(animated: false, completion: {() -> Void in
            print("situation dismissed")
            return
        })
        
        print("situationCont.close, "+String(CFGetRetainCount(self)))
    }
    
    func initPivots() {
        self.pivots.removeAll()
        
        let sequence:JSON = controller!.selectedSequence()
        let pivotTypes = ["quote", "narration", "speech"]
        if sequence.error != nil { return }
        for (index, obj) in sequence.array!.enumerated() {
            let json:JSON = obj
            let type:String = json["type"].string!
            
            if !pivotTypes.contains(type) { continue }
            
            self.pivots.append(Pivot.create(sequence, index: index))
        }
    }
    
    func initPivotsCarousel() {
        pivotsCarousel.type = .linear
        pivotsCarousel.isPagingEnabled = false
        pivotsCarousel.stopAtItemBoundary = true
        pivotsCarousel.centerItemWhenSelected = true
        pivotsCarousel.scrollSpeed = 0.5
        pivotsCarousel.reloadData()
        pivotsCarousel.scrollToItem(at: 0, animated:false)
    }
    
    func currentPlayer() -> AVPlayer {
        return self.players[currentPlayerIndex]
    }
    
    func nextPlayer() -> AVPlayer {
        return self.players[(currentPlayerIndex + 1) % self.players.count]
    }
    
    func selectPlayerAtIndex(_ idx:Int) {
        pauseAllPlayers()
        currentPlayerIndex = idx % players.count
        CATransaction.setDisableActions(true)
        for (i, p) in playerLayers.enumerated() {
            if i == currentPlayerIndex {
                p.zPosition = 1
            }
        }
        for (i, p) in playerLayers.enumerated() {
            if i != currentPlayerIndex {
                p.zPosition = 0
            }
        }
    }
    
    func switchPlayer() {
        selectPlayerAtIndex(currentPlayerIndex+1)
    }
    
    func initSinglePlayer() {
        let player = AVPlayer()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        playerLayer.frame = self.view!.bounds
        scene.layer.addSublayer(playerLayer)
        self.players.append(player)
        self.playerLayers.append(playerLayer)
    }
    
    func refresh() {
        self.renderSet(self.currentSet!)
    }

    
    func replayCurrentVoice() {
        if let cs:String = self.currentSet {
            let json:JSON = self.findSetModel(cs)
            controller?.playVoice(
                (controller?.prepareResourcePath(json["question"]["sound"].string!))!,
                callback: {() -> Bool in
                    return true
            })
        } else if let sv:URL = self.currentSpeechVoice {
            controller?.playVoice(sv, callback: {() -> Bool in
                return true
            })
        }
    }
    
    var tempQuote:JSON?
    
    func renderSet(_ set:String) {
        var json:JSON = self.findSetModel(set)
        let situationVideo = json["content"]["videos"]["situation"].string!
        let waitingVideos = json["content"]["videos"]["waitings"].arrayObject!
        
        var currentWaitingIndex = 0
        self.clearQuotes()
        if json["content"]["bgm"].string! != "" {
            audioPlayer.loop((controller?.prepareResourcePath(json["content"]["bgm"].string!))!)
        }
        if waitingVideos.count > 0 {
            self.prepareVideo(controller!.prepareResourcePath(waitingVideos[0] as! String)!)
        }
        self.looping = true
        self.tempQuote = json["content"]["quote"]
        self.perform(#selector(SituationCont.renderTempQuote), with: nil , afterDelay: 0.5)
        Async.series([
            {(nxt:@escaping Async.callbackFunc) -> Void in
                if "" == situationVideo {
                    _ = nxt()
                }
                else {
                    self.controller?.waitForResource(situationVideo, callback: {() -> Bool in
                        self.playVideo((self.controller?.prepareResourcePath(situationVideo))!, callback: {()->Bool in
                            _ = nxt()
                            return true
                        })
                        return true
                    })
                }
            } as! (() -> Bool) -> (),
            {(nxt:Async.callbackFunc) -> Void in
                if waitingVideos.count > 0  {
                    func doLoop() {
                        if !self.looping {
                            return
                        }
                        self.switchPlayer()
                        currentWaitingIndex = (currentWaitingIndex + 1) % waitingVideos.count
                        self.controller?.waitForResource(waitingVideos[currentWaitingIndex] as! String, callback: {() -> Bool in
                            self.prepareVideo((self.controller?.prepareResourcePath(waitingVideos[currentWaitingIndex] as! String)!)!)
                            self.playCurrentVideo({()->Bool in
                                doLoop()
                                return true
                            })
                            return true
                        })
                    }
                    doLoop()
                }
                _ = nxt()
            },
            {(nxt:Async.callbackFunc) -> Void in
                if json["question"]["type"] != "" {
                    self.currentQuestion = json["question"]
                    self.playCurrentQuestion()
                }
                else {
                    self.goNextSet()
                }
            }
            ], callback:{() -> Bool in
                return true
        })
    }
    
    func playCurrentQuestion() {
        self.controller?.playVoice(
            (controller?.prepareResourcePath(self.currentQuestion!["voice"].string!)!)!,
            callback: {() -> Bool in
                self.startListening(self.currentQuestion!)
                return true
        })
        if self.currentQuestion!["type"] == "keyboard" {
            self.renderAnswerAsQuote(self.currentQuestion!)
        }
    }
    
    func renderTempQuote() {
        self.renderQuote(self.tempQuote!)
    }
    
    func renderQuote(_ json:JSON) {
        let quote:JSON = json["params"]
        
        var model:JSON?
        if let key:String = quote["dialog-key"].string {
            var m:JSON = controller!.findDialogByKey(key)!
            m["position"] = quote["position"]
            m["frameless"] = quote["frameless"]
            m["waiting"] = quote["waiting"]
            m["dictation"] = quote["dictation"]
            m["dictation-translation"] = quote["dictation-translation"]
            m["dictation-memo"] = quote["dictation-memo"]
            m["dialog-key"].string = key
            m["type"] = json["type"]
            model = m
        }
        else {
            model = quote
        }
        
        // waiting 설정값 관련 처리
        var waiting:TimeInterval = 0
        
        if model!["waiting"].error == nil {
            let w:Int = model!["waiting"].intValue
            waiting = TimeInterval(w) / 1000.0
        }
        
        self.perform(#selector(SituationCont.doRenderQuote(_:)), with: model!.object, afterDelay:waiting)
        if(waiting > 0) {
            self.renderNextSequence()
        }
    }
    
    func doRenderQuote(_ obj:AnyObject) {
        guard progressing else { return }
        var model:JSON = JSON(obj)
        if model["text"].string! == "" { return }
        let view:BallonView = BallonView()
        let type:String = model["type"].string!
        
        view.delegate = self
        view.playMode = playMode
        view.setModel(model, controller:controller!)
        
        self.view!.addSubview(view)
        self.quotes.add(view)
        
        var waiting:TimeInterval = 0
        
        if model["waiting"].error == nil {
            let w:Int = model["waiting"].intValue
            waiting = TimeInterval(w) / 1000.0
        }
        
        if controller!.model?["category"].string == "picture" {
            var mute:Bool = false
            if "quote" == type
                && controller!.model?["mute-quote"] != nil
                && controller!.model?["mute-quote"].string == "true" {
                mute = true
                self.btnReplay.isHidden = false
            }
            if let param:String = model["voice"].string {
                self.currentSpeechVoice = self.controller!.prepareResourcePath(param)

                if mute || listenPaused {
                    if waiting == 0 {
                        self.renderNextSequence()
                    }
                }
                else {
                    controller?.playVoice(self.currentSpeechVoice!, callback: {() -> Bool in
                        if "talk" == self.playMode {
                            if let _:String = model["dictation"].string {
                                self.currentDictationModel = DictationModel(model, textView:nil)
                                self.currentBallonView = view;
                                self.currentAnswer = view.getDictationText()
                                self.holdNextSequence = true
                                self.showDictationArea()
                            }
                        }

                        self.btnReplay.isHidden = false
                        self.renderNextSequence()
                        return true
                    })
                }
            }
            else {
                if waiting == 0 {
                    self.renderNextSequence()
                }
            }
        }
    }
    
    func asignHtmlText(_ view:UITextView, html:String, height:CGFloat) {
        let padding:CGFloat = 20
        do {
            let str = try NSAttributedString(data: html.data(using: String.Encoding.unicode, allowLossyConversion: true)!, options: [ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
            view.attributedText = str
            
            let paragraphRect:CGRect =
                str.boundingRect(with: CGSize(width: CGFloat(1000), height: height), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            
            view.frame = CGRect(x:0, y:0, width:paragraphRect.width + padding, height:height)
            
            view.isScrollEnabled = false
        } catch {
            print(error)
        }
    }
    
    func renderAnswerAsQuote(_ quote:JSON) {
        let view:UIView = UIView()
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        view.frame = CGRect(x: quote["position"]["left"].int!, y: quote["position"]["top"].int!, width: 230, height: 40)
        view.backgroundColor = UIColor.white
        
        let leftView:UITextView = UITextView()
        let answerView:UITextField = UITextField()
        let rightView:UITextView = UITextView()
        
        leftView.isEditable = false
        rightView.isEditable = false
        
        let leftStr = quote["text"].string!.substring(to:(quote["text"].string!.range(of:"_")?.lowerBound)!)
        var rightStr = quote["text"].string!.substring(to:(quote["text"].string!.range(of:"_", options:.backwards)?.lowerBound)!)
        rightStr.remove(at: rightStr.startIndex)
        
        self.asignHtmlText(leftView, html:leftStr, height:view.frame.height)
        self.asignHtmlText(rightView, html:rightStr, height:view.frame.height)
        
        let countUnderscore:Int = quote["text"].string!.components(separatedBy: "_").count - 1
        let widthPerUnderscore:CGFloat = 10
        let widthForAnswer = CGFloat(countUnderscore) * widthPerUnderscore
        
        var x:CGFloat = 0
        leftView.frame = CGRect(x: x, y: 0, width: leftView.frame.width, height: view.frame.height)
        x += leftView.frame.width
        answerView.frame = CGRect(x: x, y: 0, width: widthForAnswer, height: view.frame.height)
        x += answerView.frame.width
        rightView.frame = CGRect(x: x, y: 0, width: rightView.frame.width, height: view.frame.height)
        
        view.addSubview(leftView)
        view.addSubview(answerView)
        view.addSubview(rightView)
        
        self.view!.addSubview(view)
        self.quotes.add(view)
        
        answerView.delegate = self
        answerView.font = UIFont.systemFont(ofSize: CGFloat(18))
        answerView.becomeFirstResponder()
    }
    
    func clearQuotes() {
        for q in self.quotes {
            (q as! UIView).removeFromSuperview()
            let qv:UIView = q as! UIView
            if q is BallonView {
                (q as! BallonView).delegate = nil
            }
            else {
                for v in qv.subviews {
                    if v is UITextField {
                        (v as! UITextField).delegate = nil
                    }
                }
            }
        }
        self.quotes.removeAllObjects()
        self.imageScene.isHidden = true
        self.btnReplay.isHidden = true
    }
    
    func clearNarrations() {
        animate {
            for n in self.narrations {
                (n as! UIView).layer.opacity = 0
            }
            }.withDuration(0.3).withOptions(.curveEaseOut)
            .completion { (finish) -> Void in
                self.clearNarrationsSync()
        }
    }

    func clearNarrationsSync() {
        for n in self.narrations {
            (n as! UIView).removeFromSuperview()
            (n as! UIControl).removeTarget(self, action: #selector(SituationCont.onTouchNarration(_:)), for: UIControlEvents.touchUpInside)
        }
        self.narrations.removeAllObjects()
        self.currentNarration = nil
    }
    
    func assignNextSet() -> Bool {
        if let items = self.model!["set"].array {
            if self.currentSet == nil {
                self.currentSet = items[0]["id"].string
                return true
            }
            else {
                var idx:Int = -1
                for (index, item) in items.enumerated() {
                    if item["id"].string == self.currentSet {
                        idx = index
                        break
                    }
                }
                if idx == -1 || idx == items.count - 1 {
                    return false
                }
                self.currentSet = items[idx+1]["id"].string
                return true
            }
        }
        else {
            return false
        }
    }
    
    func findSetModel(_ set:String) -> JSON {
        if let items = self.model!["set"].array {
            for item in items {
                if item["id"].string == set {
                    return item
                }
            }
        }
        return self.model!
    }
    
    func prepareVideo(_ url:URL) {
        nextPlayer().replaceCurrentItem(with: AVPlayerItem(url:url))
        nextPlayer().currentItem!.seek(to: CMTimeMakeWithSeconds(0.0, nextPlayer().currentTime().timescale))
    }
    
    func playCurrentVideo(_ callback:@escaping Async.callbackFunc) {
        self.videoCallback = callback
        
        
        ///// TODO : 음성과 충돌 지점
        // currentPlayer().play()

        
        let speechRecognizer = SpeechFrameworkRecognizer.instance()
        if false == speechRecognizer.getOnRecognize() {
            // 일반 재생
            currentPlayer().isMuted = false
             currentPlayer().play()
        }
        else {
            ///// 무음 재생
            currentPlayer().isMuted = true
             currentPlayer().play()
        }
    
        //let speechRecognizer = SpeechFrameworkRecognizer.instance()
            //currentPlayer().play()
        
        
        
        
        //////////////////////////////
        self.performSelector(onMainThread: #selector(SituationCont.setupVideoObserver), with: nil, waitUntilDone: false);
    }
    
    func playVideo(_ url:URL, callback:@escaping Async.callbackFunc) {
        currentPlayer().replaceCurrentItem(with: AVPlayerItem(url:url))
        self.videoCallback = callback
        currentPlayer().play()
        
        self.performSelector(onMainThread: #selector(SituationCont.setupVideoObserver), with: nil, waitUntilDone: false);
    }
    
    func setupVideoObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(SituationCont.onVideoEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: currentPlayer().currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(SituationCont.onVideoEnd(_:)), name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: currentPlayer().currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(SituationCont.onVideoEnd(_:)), name: NSNotification.Name.AVPlayerItemPlaybackStalled, object: currentPlayer().currentItem)
    }
    
    func onVideoEnd(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
        _ = self.videoCallback!()
    }
    
    func currentWebView() -> UIWebView {
        return webviews[currentWebviewIdx]
    }
    
    func candidateWebView() -> UIWebView {
        return webviews[nextWebViewIdx()]
    }
    
    func nextWebViewIdx() -> Int {
        return (currentWebviewIdx + 1) % webviews.count
    }
    
    func switchWebView() {
        print("switch webview")
        let orig:UIWebView = webviews[currentWebviewIdx]
        currentWebviewIdx = nextWebViewIdx()
        let desc:UIWebView = webviews[currentWebviewIdx]
        
        self.view.insertSubview(desc, belowSubview: orig)
        
        desc.layer.opacity = 0.0
        animate {
            desc.layer.opacity = 0.5
            }.withDuration(0.5).thenAnimate{
                desc.layer.opacity = 1
                orig.layer.opacity = 0
            }.withDuration(0.5)
            .completion({(finish) -> Void in
            })
        
        htmlCached = false
    }
    
    func restoreOnPivotIndex(_ index:Int) {
        if currentSequence == pivots[index].index {
            return
        }
        clearQuotes()
        
        let sequence:JSON = controller!.selectedSequence()
        
        let p:Pivot = self.pivots[index]
        if p.background >= 0 {
            let json:JSON = sequence[p.background]
            let type:String = json["type"].string!
            if "image" == type { renderImage(json["params"].string!); }
            else if "video" == type { renderVideo(json); }
        }
        
        currentSequence = p.resume
        
        while currentSequence <= p.index {
            let json:JSON = sequence[currentSequence]
            let type:String = json["type"].string!
            
            if "quote" == type { renderQuote(json) }
            else if "speech" == type { renderQuote(json) }
            else if "bgm" == type { renderBgm(json) }
            else if "narration" == type { renderNarration(json) }
            else if "clearQuotes" == type { clearQuotes() }
            
            currentSequence += 1
        }
    }
    
    func restoreBackgroundOnPivotIndex(_ index:Int) {
        clearQuotes()
        
        let sequence:JSON = controller!.selectedSequence()
        
        let p:Pivot = self.pivots[min(index, self.pivots.count - 1)]
        
        if p.bgm >= 0 {
            let json:JSON = sequence[p.bgm]
            renderBgm(json, next:false)
        }
        
        if p.background >= 0 {
            let json:JSON = sequence[p.background]
            let type:String = json["type"].string!
            if "image" == type { renderImage(json["params"].string!); }
            else if "video" == type { renderVideo(json); }
        }
        
        currentSequence = p.resume
        
        while currentSequence < p.index {
            let json:JSON = sequence[currentSequence]
            let type:String = json["type"].string!
            
            if "quote" == type { renderQuote(json) }
            else if "bgm" == type { renderBgm(json) }
            else if "clearQuotes" == type { clearQuotes() }
            
            currentSequence += 1
        }
        
        procListenPaused(false)
    }
    
    func resumeOnPivotIndex(_ index:Int) {
        restoreBackgroundOnPivotIndex(index)
        renderCurrentSequence()
    }
    
    func processRestoreBgTopNarration(_ callback:@escaping Async.callbackFunc) -> Bool {
        guard currentSequence > 0 else { return callback() }
        
        let sequence:JSON = controller!.selectedSequence()
        let prev:JSON = sequence[currentSequence - 1]
        let curr:JSON = sequence[currentSequence]
        
        guard prev["type"].stringValue == "next" && curr["type"].stringValue != "narration" else { return callback() }

        resetBgNarration(callback)
        
        return true
    }
    
    func restartBGMOnCurrentSequence() {
        var seq = currentSequence
        let sequence:JSON = controller!.selectedSequence()
        while true {
            if seq < 0 { break }
            let json = sequence[seq]
            if "bgm" == json["type"].stringValue {
                renderBgm(json, next:false)
                return
            }
            seq -= 1
        }
    }
    
    func renderCurrentSequence() {
        guard self.consume() == false else { self.renderNextSequence(); return }
        guard progressing == true else { return }

        self.btnNextSequence.isHidden = true
        let sequence:JSON = controller!.selectedSequence()
        let json:JSON = sequence[currentSequence]
        let type:String = json["type"].stringValue
        
        /* 나레이션 상단 그림자 영역 관련 예외 처리 */
        _ = processRestoreBgTopNarration({() -> Bool in
            if "quote" == type { self.renderQuote(json) }
            else if "image" == type { self.renderImage(json["params"].string!); self.renderNextSequence() }
            else if "sound" == type { self.renderSound(json["params"].string!) }
            else if "video" == type { self.renderVideo(json) }
            else if "video-sync" == type { self.renderVideoSync(json) }
            else if "speech" == type { if "listen" == self.playMode {self.clearQuotes(); self.renderQuote(json)} else {self.renderSpeech(json)} }
            else if "bgm" == type { self.renderBgm(json); }
            else if "narration" == type { self.clearQuotes(); self.renderNarration(json) }
            else if "next" == type { self.renderNext(json) }
            else if "clearQuotes" == type {self.clearQuotes(); self.renderNextSequence() }
            return true
        })
    }
    
    func cacheNextHtml(_ sequence:JSON) {
        if htmlCached { return }
        
        var idx:Int = currentSequence + 1
        while idx < sequence.count {
            let json:JSON = sequence[idx]
            let type:String = json["type"].string!
            if "html" == type {
                self.renderHtml(json, on:candidateWebView())
                self.htmlCached = true
                return
            }
            idx += 1
        }
    }
    
    func assignNextSequence() -> Bool {
        let sequence:JSON = controller!.selectedSequence()
        if self.currentSequence < sequence.count - 1 {
            self.currentSequence += 1
            return true
        }
        return false
    }
    
    func shouldHoldNextSequence() -> Bool {
        let sequence:JSON = controller!.selectedSequence()
        let json:JSON = sequence[currentSequence]
        let type:String = json["type"].string!
        if type == "video-sync" { return false }
        return self.holdNextSequence
    }
    
    func renderNextSequence() {
        if self.listenPaused {
            return
        }
        if self.shouldHoldNextSequence() {
            self.perform(#selector(SituationCont.renderNextSequence), with: nil, afterDelay: 0.2)
            return
        }
        if assignNextSequence() {
            renderCurrentSequence()
        }
        else {
            if "talk" == playMode {
                showScore()
            } else {
                close()
            }
        }
    }
    
    func renderNext(_ json:JSON) {
        if playMode == "listen" {
            clearQuotes()
            clearListening()
            renderNextSequence()
        }
        else {
            if json["params"].error == nil {
                if json["params"]["yield"].stringValue == "true" {
                    renderNextSequence()
                    holdNextSequence = true
                }
            }
            btnNextSequence.isHidden = false
        }
    }
    
    func renderSpeech(_ json:JSON) {
        var model:JSON?
        if let key:String = json["params"]["dialog-key"].string {
            model = controller!.findDialogByKey(key)!
            model!["voice"] = model!["voice"]
        }
        else {
            model = json["params"]
        }
        
        self.currentSpeechVoice = controller?.prepareResourcePath(model!["voice"].string!)
        
        if "listen" == playMode {
        }
        else {
            self.clearNarrations()
        }
        controller?.playVoice(self.currentSpeechVoice!, callback: {() -> Bool in
            if "listen" == self.playMode {
                self.clearQuotes()
                self.clearListening()
                self.renderNextSequence()
            } else {
                self.startListening(model!)
            }
            return true
        })
    }
    
    func renderSound(_ param:String) {
        controller?.playVoice(controller!.prepareResourcePath(param)!, callback: {() -> Bool in
            self.renderNextSequence()
            return true
        })
    }
    
    func renderImage(_ param:String) {
        self.clearQuotes()
        self.imageScene.isHidden = false
        self.imageScene.image = UIImage(data:try! Data(contentsOf: URL(string:param)!))
    }
    
    class VideoLoop {
        var nextVideo:URL?
        var looping:Bool = false
        var cont:SituationCont?
        
        init(cont:SituationCont) {
            self.cont = cont
        }
        
        func start() -> Bool {
            looping = true
            doLoop()
            return true
        }
        
        func doLoop() {
            if !looping {
                return
            }
            
            cont!.currentPlayer().pause()
            cont!.switchPlayer()
            if let video = nextVideo { cont!.prepareVideo(video) }
            cont!.playCurrentVideo({()->Bool in
                self.doLoop()
                return true
            })
        }
        
        func changeVideo(_ url:URL) {
            nextVideo = url
            cont!.prepareVideo(nextVideo!)
            cont!.currentPlayer().pause()
            cont!.switchPlayer()
            cont!.playCurrentVideo({()->Bool in
                if !self.looping { return false }
                let modelName = UIDevice.current.modelName
                if modelName == "iPhone 5" || modelName == "iPhone 5c" || modelName == "iPhone 5s" || modelName == "iPhone 6" {
                    
                }else {
                    self.changeVideo(url)
                }

                return true
            })
        }
        
        func stop() {
            looping = false
        }
    }
    
    func renderVideo(_ json:JSON) {
        self.looping = true
        if "listen" == playMode {
            self.clearQuotes()            
        }
        controller?.waitForResource(
            json["params"].string!,
            callback:{() -> Bool in
                let url = (self.controller?.prepareResourcePath(json["params"].string!)!)!
                self.videoLoop!.changeVideo(url)
                self.renderNextSequence()
                return true
        })
    }
    
    func renderVideoSync(_ json:JSON) {
        controller?.waitForResource(json["params"].string!, callback: {() -> Bool in
            self.clearQuotes()
            self.prepareVideo((self.controller?.prepareResourcePath(json["params"].string!)!)!)
            self.currentPlayer().pause()
            self.switchPlayer()
            self.playCurrentVideo({()->Bool in
                self.renderNextSequence()
                return true
            })
            return true
        })
    }
    
    func renderHtml(_ json:JSON, on:UIWebView) {
        if json["params"].string!.hasPrefix("http") {
            let html:String = "<body style='padding:0px;margin:0px;'><iframe src='"+json["params"].string!+"' style='width:100%;height:100%;border:0px'></iframe></body>"
            on.loadHTMLString(html, baseURL: nil)
        }
        else {
            on.loadRequest(URLRequest(url: (controller?.bookResourceURL(json["params"].string!))!))
        }
    }
    
    func renderBgm(_ json:JSON, next:Bool = true) {
        let resource:String = json["params"].string!
        controller!.waitForResource(resource, callback: {() -> Bool in
            self.audioPlayer.loop(self.controller!.prepareResourcePath(resource)!)
            if next {
                self.renderNextSequence()
            }
            return true
        })
    }
    
    func resetBgNarration(_ callback:@escaping Async.callbackFunc) {
        animate {
            for n in self.narrations {
                (n as! UIView).layer.opacity = 0
            }
            self.bgTopNarration.setTop((self.bgTopNarration.height) * -1)
            }.withDuration(0.3).withOptions(.curveEaseOut)
            .completion { (finish) -> Void in
                for n in self.narrations {
                    (n as! UIView).removeFromSuperview()
                }
                self.narrations.removeAllObjects()
                _ = callback()
        }
    }
    
    func renderNarration(_ json:JSON) {
        if var dialog:JSON = self.controller!.findDialogByKey(json["params"]["dialog-key"].string!) {
            controller?.waitForResource(
                dialog["voice"].string!,
                callback:{() -> Bool in
                    let narrCont = UIControl()
                    if json["params"]["position"].error == nil {
                        let p:JSON = json["params"]["position"]
                        let narr = UITextView()
                        let x:CGFloat = MainCont.scaledSize(CGFloat(p["left"].floatValue))
                        let y:CGFloat = MainCont.scaledSize(CGFloat(p["top"].floatValue),r:1)
                        
                        narrCont.frame = CGRect(x:Int(x), y:Int(y), width:Int(UIScreen.main.bounds.size.width - x * 2), height:10000)
                        narr.frame = CGRect(x:0, y:0, width:Int(UIScreen.main.bounds.size.width - x * 2), height:10000)
                        self.bgTopNarration.setWidth(UIScreen.main.bounds.size.width)
                        
                        if p["width"].error == nil {
                            let w:Int = p["width"].intValue
                            if w > 0 { narr.frame.size.width = CGFloat(w) }
                        }
                        
                        let text:String = BookController.getQuoteTextOf(dialog: dialog, params: json["params"], playMode: self.playMode!)

                        var fontSize:Int = 20
                        if json["params"]["font-size"].error == nil {
                            let fs:Int = json["params"]["font-size"].intValue
                            if fs > 0 { fontSize = fs }
                        }
                        fontSize = Int(MainCont.scaledSize(CGFloat(fontSize)))
                        
                        BallonView.setHtmlText("<span style='color:white;font-size:"+String(fontSize)+"'>"+text+"</span>", on: narr)
                        narr.isEditable = false
                        narr.isUserInteractionEnabled = false
                        narr.backgroundColor = UIColor.clear
                        narr.sizeToFit()
                        
                        narrCont.setWidth(narr.width)
                        narrCont.setHeight(narr.height)
                        
                        narrCont.addSubview(narr)
                        self.currentNarration = dialog
                        narrCont.addTarget(self, action: #selector(SituationCont.onTouchNarration(_:)), for: UIControlEvents.touchUpInside)
                        narrCont.isHidden = false

                        dialog["dictation"] = json["params"]["dictation"]
                        dialog["dictation-translation"] = json["params"]["dictation-translation"]
                        dialog["dictation-memo"] = json["params"]["dictation-memo"]
                        dialog["font-size"] = json["params"]["font-size"]
                        self.currentDictationModel = DictationModel(dialog, textView:narr)
                        
                        self.view.addSubview(narrCont)
                        narrCont.layer.opacity = 0
                        animate {
                            for n in self.narrations {
                                (n as! UIView).layer.opacity = 0
                            }
                            narrCont.layer.opacity = 1
                            self.bgTopNarration.setTop((self.bgTopNarration.height - narr.height - 160) * -1)
                            }.withDuration(0.1).withOptions(.curveEaseOut)
                            .completion { (finish) -> Void in
                                for n in self.narrations {
                                    (n as! UIView).removeFromSuperview()
                                }
                                self.narrations.removeAllObjects()
                                self.narrations.add(narrCont)
                        }
                    }
                    if self.listenPaused {
                        return true
                    }
                    
                    self.currentSpeechVoice = self.controller!.prepareResourcePath(dialog["voice"].string!)
                    self.controller!.playVoice(self.currentSpeechVoice!, callback: {() -> Bool in
                        self.btnReplay.isHidden = false
                        if "listen" == self.playMode {
                            self.renderNextSequence()
                            narrCont.isHidden = false
                            return true
                        }
                        if let dictations:String = json["params"]["dictation"].string {
                            self.currentBallonView = nil
                            self.currentAnswer = BookController.getDictationTextOf(dialog["text"].string!, dictations: dictations)
                            self.showDictationArea()
                        }
                        else {
                            self.renderNextSequence()
                        }
                        narrCont.isHidden = false
                        return true
                    })
                    return true
            })
        }
    }
    
    func onTouchNarration(_ sender:UIControl) {
        showDialogPopOver(currentNarration!)
    }
    
    func onTouchAnswerArea(_ ges:UIGestureRecognizer) {
        showDialogPopOver(currentSpeechModel!)
    }
    
    func showDictationArea() {
        dictationText.isHidden = false
        dictationText.becomeFirstResponder()
    }
    
    func showPivotsCarousel() {
        self.pivotsCarousel.isHidden = false
    }

    func hidePivotsCarousel() {
        self.pivotsCarousel.isHidden = true
    }
    
    // MARK: - PopOver
    func showDialogPopOver(_ model:JSON) {
        guard  "listen" != self.playMode! else { return }
        guard controller!.flagPlayingVoice == false else { return }
        guard dictationText.isHidden == true else { return }
        
        popOver.model = model
        
        var frame:CGRect = self.view.bounds
        frame.origin.y = self.topLayoutGuide.length
        frame.size.height -= self.topLayoutGuide.length
        popOver.view.frame = frame

        self.view.addSubview(popOver.view)
    }
    
    // MARK: - BallonView
    func ballonViewDidTouched(_ view:BallonView) {
        print("ballonViewDidTouched, "+(view.quote?.rawString()!)!)
        guard let model = view.quote else { return }
        
        showDialogPopOver(model)
    }
    
    // MARK: - Carousel
    func numberOfItems(in carousel: iCarousel) -> Int {
        return pivots.count
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        let HEIGHT:CGFloat = carousel.height
        let MARGIN:CGFloat = 6
        let WIDTH:CGFloat = HEIGHT
        
        var result:UIView?
        
        if view != nil { result = view }
        else {
            result = UIView()
        }
        
        result!.frame = CGRect(x: 0,y: 0,width: WIDTH + MARGIN,height: HEIGHT)

        if result!.subviews.count == 0 {
            result!.addSubview(PivotCell(frame:CGRect(x: 0,y: 0,width: WIDTH,height: HEIGHT)))
        }
        
        let cell:PivotCell = result!.subviews[0] as! PivotCell
        
        if pivots[index].thumbnail == nil {
            pivots[index].thumbnail = Pivot.extractThumbnail(controller!.book!._id!, sequence:controller!.selectedSequence(), pivot:pivots[index])
        }

        if let im:UIImage = pivots[index].thumbnail {
            cell.image!.image = im
        }
        
        cell.text!.text = String(index)

        if currentPivotIdx == index {
            _ = result!.borderWith(UIColor.blue, width: 3)
        }
        else {
            _ = result!.borderWith(UIColor.blue, width: 0)
        }
        return result!
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        resumeOnPivotIndex(index)
    }
    
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
    }
    
    func carouselDidScroll(_ carousel: iCarousel) {
        for i in 0..<carousel.numberOfItems {
            if let item = carousel.itemView(at: i) as? BookSetView {
                item.spaceFromCenter = carousel.offsetForItem(at: i)
            }
        }
//        restoreOnPivotIndex(carousel.currentItemIndex)
    }

    class PivotCell:UIView {
        var image:UIImageView?
        var text:UITextField?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            image = UIImageView(frame:frame)
            text = UITextField(frame:frame)
            text!.isEnabled = false
            text!.isHidden = true
            
            image!.contentMode = UIViewContentMode.scaleAspectFill
            
            addSubview(image!)
            addSubview(text!)
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder:aDecoder)
        }
    }
    
    class Pivot {
        static let backgroundTypes:[String] = ["video", "image"]
        static let bgmTypes:[String] = ["bgm"]
        static let preClearTypes:[String] = ["video", "video-sync", "image", "voice-sync"]
        static let postClearTypes:[String] = ["next", "clearQuotes"]
        
        var index:Int = 0
        var resume:Int = 0
        var background:Int = 0
        var bgm:Int = 0
        var thumbnail:UIImage?

        static func create(_ sequence:JSON, key:String) -> Pivot {
            var idx = 0
            for s in sequence.array! {
                if s["params"].error == nil && key == s["params"]["dialog-key"].stringValue {
                    return Pivot.create(sequence, index:idx)
                }
                idx += 1
            }
            return Pivot()
        }
        
        static func create(_ sequence:JSON, index:Int) -> Pivot {
            let p:Pivot = Pivot()
            
            p.index = index
            p.resume = index
            p.background = index
            p.bgm = index
            
            Pivot.findResumeIndex(sequence, pivot:p)
            Pivot.findBackgroundIndex(sequence, pivot:p)
            Pivot.findBgmIndex(sequence, pivot:p)
            
            return p
        }
        
        static func extractThumbnail(_ bookId:String, sequence:JSON, pivot:Pivot) -> UIImage {
            if pivot.background < 0 { return UIImage() }
            let json:JSON = sequence[pivot.background]
            let type:String = json["type"].stringValue
            let params:String = json["params"].stringValue
            
            if "video" == type {
                let url:URL = BookController.cachedBookResourceURL(bookId, resource: params)!
                let ua:AVURLAsset = AVURLAsset(url: url)
                let aig:AVAssetImageGenerator = AVAssetImageGenerator(asset:ua)
                aig.appliesPreferredTrackTransform = true
                do {
                    let ir:CGImage = try aig.copyCGImage(at: CMTimeMake(1, 2), actualTime: nil)
                    return UIImage(cgImage:ir)
                } catch {
                }
                return UIImage()
            }
            else if "image" == type {
                return UIImage(data:NSData(contentsOf:NSURL(string:params)! as URL)! as Data)!
            }
            
            return UIImage()
        }
        
        static func findBackgroundIndex(_ sequence:JSON, pivot:Pivot) {
            while pivot.background >= 0 {
                let json:JSON = sequence[pivot.background]
                if backgroundTypes.contains(json["type"].string!) { break }
                pivot.background -= 1
            }
        }
        
        static func findBgmIndex(_ sequence:JSON, pivot:Pivot) {
            while pivot.bgm >= 0 {
                let json:JSON = sequence[pivot.bgm]
                if bgmTypes.contains(json["type"].string!) { break }
                pivot.bgm -= 1
            }
        }
        
        static func findResumeIndex(_ sequence:JSON, pivot:Pivot) {
            while pivot.resume >= 0 {
                let json:JSON = sequence[pivot.resume]
                let type:String = json["type"].string!
                
                if preClearTypes.contains(type) { break }
                else if postClearTypes.contains(type) {
                    pivot.resume += 1
                    break
                }
                pivot.resume -= 1
            }
        }
    }
	
    @IBAction func onDictationTextChanged(_ sender: Any) {
        let tf:UITextField = sender as! UITextField
        dictationLabel.text = tf.text
    }
    
	override var inputAccessoryView: UIView? {
        dictationLabelArea.isHidden = false
        dictationLabelArea.setWidth(UIScreen.main.bounds.size.width)
        dictationLabelBackground.setWidth(dictationLabelArea.width - 20)
        dictationLabel.setWidth(dictationLabelArea.width - 36)
        dictationLabel.text = ""
        dictationLabelArea.removeFromSuperview()

        let result:UIView = UIView()
        result.frame = dictationLabelArea.frame
        dictationLabelArea.setX(0)
        dictationLabelArea.setY(0)
        result.addSubview(dictationLabelArea)
        
        return result
	}
    
    // MARK: - SpeechRecognizingDelegate
    var recentlyMicLevel:Float = 0
    
    func speechRecognizing(_ speechRecognizing:SpeechRecognizing, listening:String, level:Float) {
        self.recentlyMicLevel = level
        self.performSelector(onMainThread: #selector(SituationCont.doPulse), with: nil, waitUntilDone: false);
    }
    
    func doPulse() {
        let level = self.recentlyMicLevel
        let LEVEL_MAX:Float = 2
        let CIRCLE_MAX:Float = 180
        let CIRCLE_MIN:Float = 64
        
        let rate = min(abs(level), LEVEL_MAX) / LEVEL_MAX
        
        let size = CGFloat((CIRCLE_MAX - CIRCLE_MIN) * rate + CIRCLE_MIN)
        
        print(level, rate, size)
        
        animate {
            self.pulse.setWidth(size)
            self.pulse.setHeight(size)
            self.pulse.center = self.micButton.center
            _ = self.pulse.circle()
        }.withDuration(0.1).withOptions(.curveEaseOut).completion { (finish) -> Void in
        }
        
        pulse.isHidden = false
    }
    
    var consumeSequence:Int = 0
    
    func reserveConsumeSequence(_ count:Int) {
        consumeSequence = count
    }
    
    func consume() -> Bool {
        guard consumeSequence > 0 else { return false }
        consumeSequence -= 1
        return true
    }
}
