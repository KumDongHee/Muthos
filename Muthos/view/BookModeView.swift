//
//  BookModeView.swift
//  Muthos
//
//  Created by shining on 2016. 9. 18..
//
//

import Foundation
import SwiftAnimations

protocol BookModeViewDelegate {
    func bookModeDidChanged(view:BookModeView)
}

enum BookMode {
    case easy
    case hard
}

class BookModeView:UIView {
    var touchBegin:CGPoint = CGPoint(x:0, y:0)
    var btnBegin:CGPoint = CGPoint(x:0, y:0)
    var delegate:BookModeViewDelegate?
    var mode:BookMode = .easy {
        didSet {
            refresh()
            if let d = delegate {
                d.bookModeDidChanged(view: self)
            }
        }
    }
    
    var INITIAL_WIDTH:CGFloat = 0
    var lastWidth:CGFloat = 0
    
    override var frame:CGRect {
        didSet {
            if INITIAL_WIDTH == 0 {
                INITIAL_WIDTH = self.frame.size.width
            }
            
            self.adjustUISize()
        }
    }
    
    @IBOutlet weak var bookModeBtn: UIImageView!
    @IBOutlet weak var touchControl: UIControl!
    @IBOutlet weak var imgEasy: UIImageView!
    @IBOutlet weak var imgHard: UIImageView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    func adjustUISize() {
        guard self.frame.size.width != INITIAL_WIDTH else { return }
        guard self.frame.size.width != lastWidth else { return }
        lastWidth = self.frame.size.width
        let r = self.frame.size.width / INITIAL_WIDTH
        MainCont.adjustScaledRect(bookModeBtn, r:r)
        MainCont.adjustScaledRect(touchControl, r:r)
        MainCont.adjustScaledRect(imgEasy, r:r)
        MainCont.adjustScaledRect(imgHard, r:r)
    }
    
    func refresh() {
        if mode == .easy {
            imgEasy.image = UIImage(named:"book_mode_easy_01")
            imgHard.image = UIImage(named:"book_mode_hard_02")
        }
        else {
            imgEasy.image = UIImage(named:"book_mode_easy_02")
            imgHard.image = UIImage(named:"book_mode_hard_01")
        }
    }
    
    @IBAction func onTouchDown(_ sender: AnyObject, event:UIEvent) {
        if let button = sender as? UIControl {
            let touch = (event.touches(for: button)?.first)!
            touchBegin = touch.location(in: button)
            btnBegin = bookModeBtn.frame.origin
        }
    }
    
    @IBAction func onDragInside(_ sender: AnyObject, event:UIEvent) {
        if let button = sender as? UIControl {
            let touch = (event.touches(for: button)?.first)!
            let curr:CGPoint = touch.location(in: button)
            let deltaX:CGFloat = curr.x - touchBegin.x
            let rightBound:CGFloat = self.width - bookModeBtn.width
            
            let x:CGFloat = min(max(0, btnBegin.x + deltaX), rightBound)
            
            bookModeBtn.setX( x )
            
            let tobe:BookMode = (x > bookModeBtn.width / 2) ? .hard : .easy

            if self.mode != tobe {
                self.mode = tobe
            }
        }
    }
    
    @IBAction func onTouchUp(_ sender: AnyObject) {
        processDragEnd()
    }

    @IBAction func onClickEasy(_sender:AnyObject) {
        mode = .easy
        animate {
            self.syncPosition()
            }.withDuration(0.2).withOptions(.curveEaseOut).completion { (finish) -> Void in
        }
    }

    @IBAction func onClickHard(_sender:AnyObject) {
        mode = .hard
        animate {
            self.syncPosition()
            }.withDuration(0.2).withOptions(.curveEaseOut).completion { (finish) -> Void in
        }
    }
    
    func processDragEnd() {
        let rightBound:CGFloat = self.width - bookModeBtn.width
        if mode == .easy {
            touchControl.setX(0)
            bookModeBtn.setX(0)
        }
        else {
            touchControl.setX(rightBound)
            bookModeBtn.setX(rightBound)
        }
    }
    
    func syncPosition() {
        processDragEnd()
    }
}
