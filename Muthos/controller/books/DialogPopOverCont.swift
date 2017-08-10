//
//  DialogPopOverCont.swift
//  Muthos
//
//  Created by shining on 2016. 11. 1..
//
//

import UIKit
import SwiftyJSON

class DialogPopOverCont: UIViewController {
    var model:JSON? {
        didSet {
            refresh()
        }
    }
    
    var controller:BookController?
    var playing:Bool = false {
        didSet {
            let imageName = playing ? "control_btn_listen_ing_02" : "control_btn_listen_default_02"
            speakBtn.setImage(UIImage(named:imageName), for: .normal)
            speakBtn.setImage(UIImage(named:imageName), for: .highlighted)
            speakBtn.setImage(UIImage(named:imageName), for: .selected)
        }
    }
    
    @IBOutlet var myNoteBtnArea: UIView!
    @IBOutlet var textOrig: UITextView!
    @IBOutlet var textTrans: UITextView!
    @IBOutlet var textArea: UIView!
    @IBOutlet var speakBtn: UIButton!
    @IBOutlet var closeBtn: UIButton!
    
    @IBAction func onClickClose(sender: AnyObject?) {
        print("onClickClose")
        self.view.removeFromSuperview()
    }
    
    @IBAction func onClickMyNote(sender: AnyObject) {
        print("onClickMyNote")
        let bookId:String = (controller?.book!._id!)!
        let setIndex:String = controller!.selectedIdx!.description
        let key:String = model!["voice"].string!
        
        if hasMyNote() {
                ApplicationContext.playEffect(code: .noteOut)
        }
        else {
            ApplicationContext.playEffect(code: .noteIn)
        }
        
        ApplicationContext.sharedInstance.userViewModel.toggleMyNote(bookId, setIndex: setIndex, key: key)
        refresh()
    }
    
    @IBAction func onClickSpeaker(sender: AnyObject) {
        guard !playing else { return }
        guard let controller = self.controller else { return }
        guard let model = self.model else { return }
        guard let voice = model["voice"].string else { return }
        
        playing = true
        controller.playVoice((controller.prepareResourcePath(voice))!, callback: {() -> Bool in
            self.playing = false
            return true
        })
    }
    
    deinit {
        print("DialogPopOverCont::deinit")
    }
    
    override func viewDidLoad() {
         self.edgesForExtendedLayout = UIRectEdge()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        refresh()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        _ = myNoteBtnArea.circle()
    }
    
    func hasMyNote() -> Bool {
        let bookId:String = (controller?.book!._id!)!
        let setIndex:String = controller!.selectedIdx!.description
        let key:String = model!["voice"].string!
        
        return ApplicationContext.sharedInstance.userViewModel.hasMyNote(bookId, setIndex: setIndex, key: key)
    }
    
    func refresh() {
        guard let model = self.model else { return }
        guard textOrig != nil else { return }
        guard myNoteBtnArea != nil else { return }
        
        let text:String = model["text"].stringValue
        let translation:String = model["translation"].stringValue
        let bounds = self.view.bounds
        let PADDING:CGFloat = CGFloat(30)
        let LINE_HEIGHT:CGFloat = CGFloat(10)
        let LINE_THREASHOLD:CGFloat = CGFloat(38)
        let WIDTH:CGFloat = bounds.size.width - PADDING * 2
        
        textOrig.text = text
        textTrans.text = translation
        
        textOrig.setSize(CGSize(width:WIDTH, height:bounds.size.height))
        textTrans.setSize(CGSize(width:WIDTH, height:bounds.size.height))
        
        textOrig.sizeToFit()
        textTrans.sizeToFit()
        
        textOrig.setOrigin(CGPoint(x:0, y:0))
        textTrans.setOrigin(CGPoint(x:0, y:textOrig.height + LINE_HEIGHT))
        
        textOrig.setWidth(WIDTH)
        textTrans.setWidth(WIDTH)
        
        textOrig.textAlignment = textOrig.height > LINE_THREASHOLD ? .left : .center
        textTrans.textAlignment = textTrans.height > LINE_THREASHOLD ? .left : .center

        textArea.setSize(CGSize(width:WIDTH, height:textTrans.bottom))
        
        textArea.setX(PADDING)
        textArea.setCenterY(UIScreen.main.bounds.size.height / 2 - (UIScreen.main.bounds.size.height - bounds.size.height))
        
        myNoteBtnArea.setCenterX(bounds.size.width / 2)
        myNoteBtnArea.setCenterY(textArea.top / 2)
        
        let has = hasMyNote()
        myNoteBtnArea.subviews[0].isHidden = has
        myNoteBtnArea.subviews[1].isHidden = !has
    }
}
