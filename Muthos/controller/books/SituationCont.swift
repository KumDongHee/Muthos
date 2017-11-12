//
//  SituationCont.swift
//  Muthos
//
//  Created by Youngjune Kwon on 2016. 1. 16..
//
//

func fontsizeForDevice(size : Double) -> Double{
    if UIDevice.current.userInterfaceIdiom == .pad {
        return size / 2
    }
    return size
}

import Foundation
import UIKit
import AVFoundation
import QuartzCore
import SwiftyJSON
import SwiftAnimations
import iCarousel

class SituationCont : DefaultCont, UITextFieldDelegate, iCarouselDataSource, iCarouselDelegate, SituationItemDelegate, SpeechRecognizingDelegate {
    var controller:BookController?
    var recognizing:Bool = false
    var aUnit:AudioUnit?
    var micOverLayer:CALayer = CALayer()
    var model:JSON?
    var currentPlayerIndex : Int = 0
    var progressing:Bool = false
    var audioPlayer:AVAsyncPlayer = AVAsyncPlayer()
    var videoLoop:VideoLoop?
    var videoCallback:Async.callbackFunc?
    var players : [AVPlayer] = []
    var playerLayers : [AVPlayerLayer] = []
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
    var currentSpeechVoice:URL?
    var holdNextSequence:Bool = false
    var currentSituationItem:SituationItem?
    var playMode:String? = ""
    var listenPaused:Bool = false
    var pivots:[Pivot] = []
    
    let quotes:NSMutableArray = NSMutableArray()
    let narrations:NSMutableArray = NSMutableArray()
    var popOver:DialogPopOverCont = BookController.loadViewController("Situation", viewcontroller: "DialogPopOverCont") as! DialogPopOverCont
    
    @IBOutlet weak var btnNext: UIButton!
    @IBOutlet weak var btnRetry: UIButton!
    @IBOutlet weak var btnNextSequence: UIButton!
    @IBOutlet weak var resultArea: UIView!
    @IBOutlet weak var micArea: UIView!
    @IBOutlet weak var talkAnswer: UIView!
    @IBOutlet weak var scene: UIView!
    @IBOutlet weak var scoreImage: UIImageView!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var lightImage: UIImageView!
    @IBOutlet weak var retryBedgeArea: UIView!
    @IBOutlet weak var retryCountLbl: UILabel!
    @IBOutlet var webviews: [UIWebView]!
    @IBOutlet var screens: [UIView]!
    @IBOutlet weak var imageScene: UIImageView!
    @IBOutlet weak var dictationText: UITextField!
    @IBOutlet weak var dictationLabelArea: UIView!
    @IBOutlet weak var dictationLabel: UILabel!
    @IBOutlet weak var dictationLabelBackground: UIView!
    
    @IBOutlet weak var dictationTipsArea: UIView!
    @IBOutlet weak var dictationTipsOrigin: UILabel!
    @IBOutlet weak var dictationTipsWords: UILabel!
    @IBOutlet weak var dictationTipsTranslation: UILabel!
    @IBOutlet weak var dictationTipsMemo: UILabel!
    
    @IBOutlet weak var listenArea: UIView!
    @IBOutlet weak var btnPauseListen: UIButton!
    @IBOutlet weak var pivotsCarousel: iCarousel!

    @IBOutlet weak var pulse: UIView!
    @IBOutlet weak var btnReplay: UIButton!

    @IBAction func onTogglePauseListen(_ sender: AnyObject) {
        procListenPaused(!listenPaused)
    }
    
    var answerBallon : BallonView?
    
    deinit {
        print("deinit, SituationCont")
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
        
        if model?["category"].string == "picture" {
            self.clearDialogItems()
            self.clearListening()
            if self.holdNextSequence == true {
                self.holdNextSequence = false
            }
            else {
                self.renderNextSequence()
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
        if model?["category"].string == "picture" {
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
            _ = self.controller!.recognizer!.recognize(callback:{() -> Bool in
                self.showResultArea(self.getSequenceModel(self.controller!.selectedSequence()[self.currentSequence]),desc: self.controller!.recognizer!.recognized)
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
    
    func showDictationResult(_ desc:String) {
        print(dictationLabelArea.frame)
        dictationText.isHidden = true
        dictationLabelArea.isHidden = true
        
        let images:[String] = ["control_result_fail", "control_result_success"]
        let lightImages:[String] = ["control_result_light_violet", "control_result_light_yellow"]
        let effects:[SOUND_CODE] = [.fail, .success]
        let json:JSON = BookController.evaluateSentence((currentSituationItem?.getDictationText())!, desc: desc)
        
        talkAnswer.isHidden = false
        resultArea.isHidden = false
        micArea.isHidden = true
        
        retryBedgeArea.isHidden = true
        btnRetry.isHidden = true
        
        let grade:Int = json["grade"].intValue == 5 ? 1 : 0
        scoreImage.image = UIImage(named: images[grade])
        lightImage.image = UIImage(named:lightImages[grade])

        ApplicationContext.playEffect(code: effects[grade])
        
        self.controller!.writeBonus((currentSituationItem?.quote!["text"].string)!, grade: grade)
        
        currentSituationItem?.showDictationResult()
        showDictationTips((currentSituationItem?.quote)!, result:json)
        
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

        var html:String = BookController.getDictationResultOf(model["text"].string!,
                                                              dictations: dictations,
                                                              correct:correct, desc:result["desc"].string!)
        html = "<span style='color:white;font-size:18px'>" + html + "</span>"
        
        dictationTipsOrigin.setHtmlText(html)

        dictationTipsWords.text = model["text"].string!
        
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
    
    func getSequenceModel(_ sequence : JSON) -> JSON? {
        let quote:JSON = sequence["params"]
        
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
            m["type"] = sequence["type"]
            model = m
        }
        else {
            model = sequence
        }
        return model
    }
    
    
    func showResultArea(_ model : JSON?,desc:String) {
        audioPlayer.resumeLooping()
        
        let images:[String] = ["control_result_30", "control_result_50", "control_result_70", "control_result_90", "control_result_100"]
        let effects:[SOUND_CODE] = [.bad, .notBad, .good, .excellent, .perfect]
        
        answerBallon = BallonView.init(quote: model!, playmode : playMode!)
        let grade : Int = (answerBallon?.changeToAnswerBallon(recognized: desc, flexibility: model!["flexibility"]))!
        answerBallon?.delegate = self
        answerBallon?.playMode = playMode
        
        answerBallon?.frame.origin.y = max((answerBallon?.frame.origin.y)!, UIApplication.shared.statusBarFrame.size.height + (navigationController?.navigationBar.frame.size.height)! + 8)
        
        answerBallon?.isHidden = true
        self.view.addSubview(answerBallon!)
        
        self.lightImage.image = UIImage(named:"control_result_light_yellow")
        
        self.controller!.writeScore(model!["voice"].string!, grade: grade)
        
        self.retryCountLbl.text = String(currentRetry)
        
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
        scoreImage.transform = moveDown
        btnNext.transform = moveDown
        btnRetry.transform = moveDown
        answerBallon?.transform = scaleDown
        retryBedgeArea.transform = scaleDown
        
        animate {
            self.pulse.isHidden = true
            self.micButton.transform = scaleDown
            self.micOverLayer.opacity = 1.0
            }.withOptions(.curveEaseOut).withDuration(0.2).thenAnimate({_ -> Void in
                self.micButton.center = CGPoint(x: micCenter.x, y: micCenter.y+10)
            }).withDuration(0.11).withOptions(.curveEaseOut).thenAnimate({_ -> Void in
//                self.micButton.center = CGPoint(x: micCenter.x, y: self.answerArea.frame.midY + self.micButton.frame.size.height/2.0)
                self.micButton.center = (self.answerBallon?.center)!
                
                self.micButton.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                self.resultArea.isHidden = false
            }).withDuration(0.33).withOptions(.curveEaseIn).thenAnimate({_ -> Void in
                self.answerBallon?.isHidden = false
                self.answerBallon?.transform = CGAffineTransform.identity
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
                
                    self.micArea.isHidden = true
                    self.micButton.transform = CGAffineTransform.identity
                    self.micOverLayer.opacity = 0.0
                    self.micButton.center = micCenter
                    self.setRecoginzingStatus(false)
                    self.playResultAreaAnimation()
                
        }
        
        ApplicationContext.sharedInstance.userViewModel.appendExp(1,memo:"speech")
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
    
    func initRetryCount() {
        currentRetry = (ApplicationContext.sharedInstance.userViewModel.currentUserObject()?.getRetry())!
    }
    
    func clearListening() {
        resultArea.isHidden = true
        micArea.isHidden = false
        talkAnswer.isHidden = true
        dictationTipsArea.isHidden = true
        
        retryBedgeArea.isHidden = false
        btnRetry.isHidden = false
        
        answerBallon?.removeFromSuperview()
        answerBallon = nil
    }
    
    func startListening(_ model:JSON) {
        resultArea.isHidden = true
        micArea.isHidden = false
        talkAnswer.isHidden = false
        
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

        
        initSinglePlayer()
        initSinglePlayer()
        videoLoop = VideoLoop(cont:self)
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
    
    var flagReserveStart:Bool = false
    var onceWorked:Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isTranslucent = true

        navigationController?.navigationBar.hideLine()
        let index:String = controller!.model!["sets"][controller!.selectedIdx!]["index"].stringValue
        let title:String = "Set " + index
        (self.navigationItem.titleView?.subviews[0] as! UILabel).text = title
        
        _ = videoLoop!.start()
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
        clearDialogItems()
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
                if self.model?["category"].string == "picture" {
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
        self.showDictationResult(self.dictationText.text!)
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
        
        
        if self.recognizing == true {
            self.micButton.isEnabled = false
            DispatchQueue.main.asyncAfter(deadline: (DispatchTime.now() + 1)) {
                self.controller!.recognizer!.stopRecognizing()
            }
            return
        }
        popOver.onClickClose(sender: nil)
        
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
        pauseAllPlayers()
        videoLoop!.stop()
        clearDialogItems()
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
    
    func replayCurrentVoice() {
        if let sv:URL = self.currentSpeechVoice {
            controller?.playVoice(sv, callback: {() -> Bool in
                return true
            })
        }
    }
    
    func renderQuote(_ model : JSON?) {
        
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
        let ballonView:BallonView = BallonView.init(quote: model, playmode: playMode!)
        let type:String = model["type"].string!
        
        ballonView.delegate = self
        
        ballonView.frame.origin.y = max(ballonView.frame.origin.y, UIApplication.shared.statusBarFrame.size.height + (navigationController?.navigationBar.frame.size.height)! + 8)
        
        self.view!.addSubview(ballonView)
        self.quotes.add(ballonView)
        
        self.currentSituationItem = ballonView
        
        var waiting:TimeInterval = 0
        
        if model["waiting"].error == nil {
            let w:Int = model["waiting"].intValue
            waiting = TimeInterval(w) / 1000.0
        }
        
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
    
    func clearDialogItems() {
        for q in self.quotes {
            (q as! UIView).removeFromSuperview()
        }
        self.quotes.removeAllObjects()
        
        for n in self.narrations {
            (n as! UIView).removeFromSuperview()
        }
        self.narrations.removeAllObjects()
        self.imageScene.isHidden = true
        self.btnReplay.isHidden = true
        self.currentSituationItem = nil
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
        clearDialogItems()
        
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
            let sequence:JSON = sequence[currentSequence]
            let model = getSequenceModel(sequence)
            let type:String = model!["type"].string!
            
            if "quote" == type { renderQuote(model) }
            else if "speech" == type { renderQuote(model) }
            else if "bgm" == type { renderBgm(model!) }
            else if "narration" == type { renderNarration(model!) }
            else if "clearQuotes" == type { clearDialogItems() }
            
            currentSequence += 1
        }
    }
    
    func restoreBackgroundOnPivotIndex(_ index:Int) {
        clearDialogItems()
        
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
            let model = getSequenceModel(json)
            let type:String = model!["type"].string!
            
            if "quote" == type { renderQuote(model) }
            else if "bgm" == type { renderBgm(model!) }
            else if "clearQuotes" == type { clearDialogItems() }
            
            currentSequence += 1
        }
        
        procListenPaused(false)
    }
    
    func resumeOnPivotIndex(_ index:Int) {
        restoreBackgroundOnPivotIndex(index)
        renderCurrentSequence()
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
        let sequence:JSON = controller!.selectedSequence()[currentSequence]
        let model:JSON = getSequenceModel(sequence)!
        let type:String = model["type"].stringValue
        
        if "quote" == type { self.renderQuote(model) }
        else if "image" == type { self.renderImage(model["params"].string!); self.renderNextSequence() }
        else if "sound" == type { self.renderSound(model["params"].string!) }
        else if "video" == type { self.renderVideo(model) }
        else if "video-sync" == type { self.renderVideoSync(model) }
        else if "speech" == type { self.clearDialogItems(); if "listen" == self.playMode {self.renderQuote(model)} else {self.renderSpeech(model)} }
        else if "bgm" == type { self.renderBgm(model); }
        else if "narration" == type { self.clearDialogItems(); self.renderNarration(model) }
        else if "next" == type { self.renderNext(model) }
        else if "clearQuotes" == type {self.clearDialogItems(); self.renderNextSequence() }
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
            clearDialogItems()
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
    
    func renderSpeech(_ model : JSON?) {
        
        self.currentSpeechVoice = controller?.prepareResourcePath(model!["voice"].string!)
        
        self.clearDialogItems()
        
        controller?.playVoice(self.currentSpeechVoice!, callback: {() -> Bool in
            self.startListening(model!)
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
        self.clearDialogItems()
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
                if modelName == "iPhone 5" || modelName == "iPhone 5c" || modelName == "iPhone 5s" || modelName == "iPhone 6" || modelName == "iPad Air" || modelName == "iPad Air 2" || modelName == "iPad mini 3" || modelName == "iPad mini 4" || modelName == "iPad 4" {
                    
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
        if "listen" == playMode {
            self.clearDialogItems()
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
            self.clearDialogItems()
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
    
    func renderNarration( _ model : JSON) { // narration 독립적인 뷰로 빠져야함
        controller?.waitForResource(
            model["voice"].string!,
            callback:{() -> Bool in
                
                let narrationView:NarrationView = NarrationView.init(quote: model, playmode : self.playMode!)
                
                narrationView.delegate = self
                
                self.currentSituationItem = narrationView
                
                self.view.addSubview(narrationView)
                narrationView.frame.origin.y = (self.navigationController?.navigationBar.frame.size.height)! + UIApplication.shared.statusBarFrame.size.height
                self.narrations.add(narrationView)
                if self.listenPaused {
                    return true
                }
                
                self.currentSpeechVoice = self.controller!.prepareResourcePath(model["voice"].string!)
                self.controller!.playVoice(self.currentSpeechVoice!, callback: {() -> Bool in
                    self.btnReplay.isHidden = false
                    if "listen" == self.playMode {
                        self.renderNextSequence()
                        narrationView.isHidden = false
                        return true
                    }
                    if let _ = model["dictation"].string {
                        self.showDictationArea()
                    }
                    else {
                        self.renderNextSequence()
                    }
                    narrationView.isHidden = false
                    return true
                })
                return true
        })
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
    
    // MARK: - Popover
    func SituationItemDidTapped(item: SituationItem, quote: JSON) {
        
        guard  "listen" != self.playMode! else { return }
        guard controller!.flagPlayingVoice == false else { return }
        guard dictationText.isHidden == true else { return }
        
        popOver.model = quote
        
        var frame:CGRect = self.view.bounds
        frame.origin.y = self.topLayoutGuide.length
        frame.size.height -= self.topLayoutGuide.length
        popOver.view.frame = frame
        
        self.view.addSubview(popOver.view)
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
        let LEVEL_MAX:Float = 0.2
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
        }.withDuration(0.15).withOptions(.curveEaseOut).completion { (finish) -> Void in
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


extension UILabel {
    
    func setHtmlText(_ html:String) {
        let BACKGROUND_STANDARD_WIDTH : CGFloat = 375
        let fontsize : Int = Int(18 * pow(UIScreen.main.bounds.size.width / BACKGROUND_STANDARD_WIDTH,1/2))
        let PREFIX:String = "<span style='font-size:\(fontsize)px;AppleGothic;font-family:Apple SD Gothic Neo;font-weight:400;'>"
        let SUFFIX:String = "</span>"
        
        do {
            let myStr:String = PREFIX+html+SUFFIX
            let str = try NSMutableAttributedString(data: myStr.data(using: String.Encoding.unicode, allowLossyConversion: true)!, options: [ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
            
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineSpacing = -2.0
            str.addAttribute(NSParagraphStyleAttributeName, value:paraStyle, range:NSMakeRange(0, str.length))
            
            self.attributedText = str
        } catch {
            print(error)
        }
    }
}
