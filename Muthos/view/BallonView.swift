//
//  BallonView.swift
//  Muthos
//
//  Created by Youngjune Kwon on 2016. 3. 3..
//
//

import UIKit
import SwiftyJSON

protocol BallonViewDelegate {
    func ballonViewDidTouched(_:BallonView)
}

class BallonView:UIView {
    enum TriangleEdge {
        case bottomLeft
        case bottomRight
        case topLeft
        case topRight
        case leftUp
        case leftDown
        case rightUp
        case rightDown
    }
    
    let triangle:TriangleView = TriangleView()
    var quote:JSON?
    var controller:BookController?
    var translationView:UIView?
    var translationText:UITextView?
    let quoteView:UITextView = UITextView()
    let quoteBackground:UIView = UIView()
    var edge:TriangleEdge = TriangleEdge.bottomLeft
    var edgeEnd:CGPoint = CGPoint()
    var status:String = "ordinary"
    let btnMyNote:UIControl = UIControl()
    let markMyNote:UIImageView = UIImageView()
    var ordinaryRect:CGRect?
    var playMode:String? = ""
    var delegate:BallonViewDelegate?
    static let HIGHLIGHTED_COLOR:UIColor = UIColor(red: 0, green: 122, blue: 255)
    static let TRANSLATION_COLOR:UIColor = UIColor(white:0, alpha:0.8)
    static let MARGIN:CGFloat = 3
    static let PADDING_MYNOTE:CGFloat = 15
    
    
    
    
    func setModel(_ quote:JSON, controller:BookController) {
        self.quote = quote
        self.controller = controller

        initQuoteView()
        
        var positionChange : String = "position"
        if UIDevice.current.userInterfaceIdiom == .pad {
            if quote["padPosition"].error == nil {
            positionChange = "padPosition"
            }
        }
        var x:CGFloat = MainCont.scaledSize(CGFloat(quote["\(positionChange)"]["left"].floatValue))
        var y:CGFloat = MainCont.scaledSize(CGFloat(quote["\(positionChange)"]["top"].floatValue))
        
        
//        var x:CGFloat = MainCont.scaledSize(CGFloat(quote["position"]["left"].floatValue))
//        var y:CGFloat = MainCont.scaledSize(CGFloat(quote["position"]["top"].floatValue))
        
        
        x = x < 0 ? UIScreen.main.bounds.size.width + x - quoteBackground.width : x
        y = y < 0 ? UIScreen.main.bounds.size.height + y - quoteBackground.height : y
        
        self.frame = CGRect(x: Int(x), y: Int(y), width: Int(quoteBackground.width), height: Int(MainCont.scaledSize(40)))
        
        initEdge()
        initTranslationView()
        initTriangleView()
        initMyNoteButton()
        addSubview(triangle)

        let fl:Bool = quote["frameless"].boolValue
        if fl {
            self.quoteBackground.backgroundColor = UIColor.clear
            self.triangle.tintColor = UIColor.clear
        }

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BallonView.onQuoteTapped(_:))))
//        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(BallonView.onQuotePressed(_:))))
//        let swipeDownGesture = UISwipeGestureRecognizer(target:self, action:#selector(BallonView.onSwipeDown(_:)))
//        swipeDownGesture.direction = UISwipeGestureRecognizerDirection.down
//        let swipeUpGesture = UISwipeGestureRecognizer(target:self, action:#selector(BallonView.onSwipeUp(_:)))
//        swipeUpGesture.direction = UISwipeGestureRecognizerDirection.up
//        
//        addGestureRecognizer(swipeDownGesture)
//        addGestureRecognizer(swipeUpGesture)

        refresh()
        
        self.transform = CGAffineTransform(scaleX: MainCont.SIZE_RATIO, y: MainCont.SIZE_RATIO)
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.transform = CGAffineTransform(scaleX: MainCont.SIZE_RATIO * 2/3, y: MainCont.SIZE_RATIO * 2/3)
        }
        
    }
    
    func isEmptyEdgeEnd() -> Bool {
        return edgeEnd.x == 0 && edgeEnd.y == 0
    }
    
    func initEdge() {
        edge = .bottomLeft
        edgeEnd.x = 0
        edgeEnd.y = 0
        
        var changePosition = "position"
        if UIDevice.current.userInterfaceIdiom == .pad {
            if quote!["padPosition"].error == nil {
                changePosition = "padPosition"
            }
        }
        
        guard let quote = quote else { return }
        guard quote["\(changePosition)"]["tail"].error == nil else { return }
        
        let tailString = quote["\(changePosition)"]["tail"].stringValue
        let arr:[String] = tailString.components(separatedBy: ",")
        guard let tail:Int = Int(arr[0]) else {return}
        
        let edges:[TriangleEdge] = [.bottomLeft, .bottomRight, .rightDown, .rightUp, .topRight, .topLeft, .leftUp, .leftDown]

        guard tail > 0 && tail <= edges.count else { return }

        edge = edges[tail - 1]
        
        guard arr.count > 2 else { return }
        guard let x:Float = Float(arr[1]) else {return}
        guard let y:Float = Float(arr[2]) else {return}
        
        edgeEnd.x = CGFloat(x < 0 ? Float(UIScreen.main.bounds.size.width) + x : x)
        edgeEnd.y = CGFloat(y)
    }
    
    func initTranslationView() {
        if let s:String = self.quote!["translation"].string {
            
            translationText = UITextView()
            translationText!.isEditable = false
            translationText!.frame = CGRect(x: 0,y: 0,width: quoteView.width,height: quoteView.height)
            translationText!.layer.cornerRadius = 3
            translationText!.text = s
            translationText!.sizeToFit()
            translationText!.setWidth(quoteView.width)
            translationText!.textColor = UIColor.white
            translationText!.backgroundColor = BallonView.TRANSLATION_COLOR
            
            translationView = UIView()
            translationView!.frame = CGRect(x: 0,y: 0,width: translationText!.width,height: translationText!.height+10)
            
            let triangle = TriangleView()
            triangle.frame = CGRect(x: translationView!.width/2-5,y: translationText!.height, width: 10,height: 10)
            triangle.backgroundColor = UIColor.clear
            triangle.tintColor = BallonView.TRANSLATION_COLOR
            triangle.point = TriangleView.PointPosition.downCenter
            
            translationView!.addSubview(translationText!)
            translationView!.addSubview(triangle)

            translationView!.isHidden = true
            
            translationView!.setBottom(BallonView.MARGIN * -1)
            addSubview(translationView!)
        }
    }
    
    let PADDING_WIDTH:CGFloat = 8
    let X_MOVE:CGFloat = 1
    
    func initQuoteView() {
        quoteView.isEditable = false
        quoteView.isUserInteractionEnabled = false
        quoteView.backgroundColor = UIColor.clear

        quoteBackground.layer.cornerRadius = 3
        quoteBackground.layer.masksToBounds = true
        quoteView.frame = CGRect(x: 0, y: 0, width: 300, height: 40)
        let w:Int = self.quote!["position"]["width"].intValue
        if w > 0 {
            quoteView.frame.size.width = CGFloat(w)
        }
        
        BallonView.setHtmlText(self.getQuoteText(), on: quoteView)
        quoteView.sizeToFit()
        ordinaryRect = CGRect(x: quoteView.x, y: quoteView.x, width: quoteView.width+PADDING_WIDTH*2, height: quoteView.height)
        
        quoteBackground.frame = ordinaryRect!
        addSubview(quoteBackground)
        quoteBackground.addSubview(quoteView)
        quoteView.frame = CGRect(x: PADDING_WIDTH+X_MOVE,y: 0,width: quoteView.width, height: quoteView.height)
        setNeedsLayout()
    }
    
    func initMyNoteButton() {
        btnMyNote.addTarget(self, action: #selector(BallonView.onToggleMyNote(_:)), for: UIControlEvents.touchUpInside)
        btnMyNote.frame = CGRect(x: 0,y: 0,width: 33,height: 23)
        btnMyNote.setCenterX(quoteView.centerX)
        btnMyNote.setY(quoteView.height + BallonView.PADDING_MYNOTE)
        
        let icon:UIImageView = UIImageView()
        icon.image = UIImage(named:"control_btn_add_book")
        icon.frame = CGRect(x: 0,y: 0,width: 21,height: 23)

        markMyNote.image = UIImage(named:"control_btn_add_arrow")
        markMyNote.frame=CGRect(x: 0,y: 0,width: 11,height: 9)
        markMyNote.setCenterY(btnMyNote.height / 2)
        markMyNote.setRight(btnMyNote.width)
        
        btnMyNote.addSubview(icon)
        btnMyNote.addSubview(markMyNote)
        
        addSubview(btnMyNote)
    }
    
    func refresh() {
        if "ordinary" == self.status {
            btnMyNote.isHidden = true
            quoteBackground.frame = ordinaryRect!
            setHighlighted(false)
        }
        else if "my-note" == self.status {
            btnMyNote.isHidden = false
            let appendedHeight:CGFloat = btnMyNote.height + BallonView.PADDING_MYNOTE * 2
            quoteBackground.setHeight(ordinaryRect!.size.height + appendedHeight)
            setHighlighted(true)
        }
        
        if TriangleEdge.bottomLeft == edge || TriangleEdge.bottomRight == edge {
            triangle.setY(quoteBackground.height)
        }
        
        setHeight(quoteBackground.height)
        
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.4
        self.layer.shadowRadius = 2
        self.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
    }
    
    func showDictationResult() {
        BallonView.showDictationResultOn(textView: quoteView, model: self.quote!)
        initTriangleView()
    }
    
    static func showDictationResultOn(textView:UITextView, model:JSON, white:Bool = false, fontSize:Int = -1) {
        let text:String = model["text"].string!
        var fontString:String = fontSize > 0 ? "font-size:" + String(fontSize) : ""
        if let fs:Int = model["font-size"].intValue {
            if fs > 0 { fontString = "font-size:" + String(fs) }
        }
        if let dictations:String = model["dictation"].string {
            var html:String = BookController.getDictationResultOf(text, dictations: dictations)
            html = "<span style='color:"+(white ? "white" : "black")+";"+fontString+"'>" + html + "</span>"
            BallonView.setHtmlText(html, on: textView)
            textView.sizeToFit()
        }
    }
    
    func getQuoteText() -> String {
        return BookController.getQuoteTextOf(dialog: self.quote!, params: self.quote!, playMode: playMode!, hideColor:"white")
    }
    
    func getDictationText() -> String {
        return BookController.getDictationTextOf(self.quote!["text"].string!, dictations:self.quote!["dictation"].string!)
    }

    let PADDING:CGFloat = 12
    
    func initTriangleView() {
        triangle.baseline = 10
        triangle.backgroundColor = UIColor.clear
        triangle.tintColor = UIColor.white

        let origins:[TriangleEdge:CGPoint] = [
            .bottomLeft:    CGPoint(x:PADDING, y:quoteView.height),
            .bottomRight:   CGPoint(x:quoteBackground.width - PADDING, y:quoteView.height),
            .topLeft:       CGPoint(x:PADDING, y:0),
            .topRight:      CGPoint(x:quoteBackground.width - PADDING, y:0),
            .leftUp:        CGPoint(x:0, y:PADDING),
            .leftDown:      CGPoint(x:0, y:quoteBackground.height - PADDING),
            .rightUp:       CGPoint(x:quoteBackground.width, y:PADDING),
            .rightDown:     CGPoint(x:quoteBackground.width, y:quoteBackground.height - PADDING)
        ]
        
        guard let origin = origins[edge] else { return }

        let defaultEndCoords:[TriangleEdge:CGPoint] = [
            .bottomLeft:    CGPoint(x:origin.x + triangle.baseline, y:origin.y + triangle.baseline),
            .bottomRight:   CGPoint(x:origin.x - triangle.baseline, y:origin.y + triangle.baseline),
            .topLeft:       CGPoint(x:origin.x + triangle.baseline, y:origin.y - triangle.baseline),
            .topRight:      CGPoint(x:origin.x - triangle.baseline, y:origin.y - triangle.baseline),
            .leftUp:        CGPoint(x:origin.x - triangle.baseline, y:origin.y + triangle.baseline),
            .leftDown:      CGPoint(x:origin.x - triangle.baseline, y:origin.y - triangle.baseline),
            .rightUp:       CGPoint(x:origin.x + triangle.baseline, y:origin.y + triangle.baseline),
            .rightDown:     CGPoint(x:origin.x + triangle.baseline, y:origin.y - triangle.baseline)
        ]
        
        guard let end = isEmptyEdgeEnd()
            ? defaultEndCoords[edge]
            : CGPoint(x:edgeEnd.x - self.x, y:edgeEnd.y - self.y) else {return}
        
        let thirdCoords:[TriangleEdge:CGPoint] = [
            .bottomLeft:    CGPoint(x:origin.x + triangle.baseline, y:origin.y),
            .bottomRight:   CGPoint(x:origin.x - triangle.baseline, y:origin.y),
            .topLeft:       CGPoint(x:origin.x + triangle.baseline, y:0),
            .topRight:      CGPoint(x:origin.x - triangle.baseline, y:0),
            .leftUp:        CGPoint(x:0, y:origin.y + triangle.baseline),
            .leftDown:      CGPoint(x:0, y:origin.y - triangle.baseline),
            .rightUp:       CGPoint(x:origin.x, y:origin.y + triangle.baseline),
            .rightDown:     CGPoint(x:origin.x, y:origin.y - triangle.baseline)
        ]
        
        guard let third = thirdCoords[edge] else { return }
        
        triangle.point = calcPointPosition(origin, end)
        triangle.frame = calcTriangleRectFor([origin, end, third])
    }
    
    func calcPointPosition(_ origin:CGPoint,_ end:CGPoint) -> TriangleView.PointPosition {
        if TriangleEdge.bottomLeft == edge || TriangleEdge.bottomRight == edge {
            return origin.x < end.x ? TriangleView.PointPosition.bottomRight : TriangleView.PointPosition.bottomLeft
        }
        else if TriangleEdge.topLeft == edge || TriangleEdge.topRight == edge {
            return origin.x < end.x ? TriangleView.PointPosition.topRight : TriangleView.PointPosition.topLeft
        }
        else if TriangleEdge.rightUp == edge || TriangleEdge.rightDown == edge {
            return origin.y < end.y ? TriangleView.PointPosition.rightDown : TriangleView.PointPosition.rightUp
        }
        else if TriangleEdge.leftUp == edge || TriangleEdge.leftDown == edge {
            return origin.y < end.y ? TriangleView.PointPosition.leftDown : TriangleView.PointPosition.leftUp
        }
        
        return TriangleView.PointPosition.bottomLeft
    }
    
    func calcTriangleRectFor(_ arr:[CGPoint]) -> CGRect {
        var minX:CGFloat = CGFloat(Int.max), minY:CGFloat = CGFloat(Int.max), maxX:CGFloat = 0, maxY:CGFloat = 0
        
        for p in arr {
            if p.x < minX { minX = p.x }
            if p.x > maxX { maxX = p.x }
            if p.y < minY { minY = p.y }
            if p.y > maxY { maxY = p.y }
        }
        
        return CGRect(x:minX, y:minY, width:maxX - minX, height:maxY - minY)
    }
    
    func setTrianglePosition() {
    }
    
    func setHighlighted(_ highlighted:Bool) {
        if highlighted {
            quoteBackground.backgroundColor = BallonView.HIGHLIGHTED_COLOR
            triangle.tintColor = BallonView.HIGHLIGHTED_COLOR
            BallonView.setHtmlText("<font color='white'>"+self.getQuoteText()+"</font>", on: quoteView)
        }
        else {
            quoteBackground.backgroundColor = UIColor.white
            triangle.tintColor = UIColor.white
            BallonView.setHtmlText(self.getQuoteText(), on: quoteView)
        }
        triangle.layer.setNeedsDisplay()
    }
    
    func onQuoteTapped(_ ges:UIGestureRecognizer) {
        guard let delegate = delegate else { return }
        delegate.ballonViewDidTouched(self)
        
//        if "ordinary" != status {
//            if "my-note" == status {
//                status = "ordinary"
//                let bookId:String = (controller?.book!._id!)!
//                let setIndex:String = controller!.selectedIdx!.description
//                let key:String = self.quote!["dialog-key"].string!
//                ApplicationContext.sharedInstance.userViewModel.toggleMyNote(bookId, setIndex: setIndex, key: key)
//                refresh()
//            }
//            return
//        }
//        if let v:String = self.quote!["voice"].string {
//            setHighlighted(true)
//            status = "playing"
//            self.controller?.playVoice((self.controller?.bookResourceURL(v))!, callback: {() -> Bool in
//                self.setHighlighted(false)
//                self.status = "ordinary"
//                return true
//            })
//        }
    }
    
    func onQuotePressed(_ ges:UIGestureRecognizer) {
        if "ordinary" != status || "listen" == playMode { return }
        if let view:UIView = self.translationView {
            if UIGestureRecognizerState.began == ges.state {
                view.isHidden = false
            }
            else if UIGestureRecognizerState.ended == ges.state {
                view.isHidden = true
            }
        }
    }
    
    func onSwipeDown(_ ges:UIGestureRecognizer) {
        if "ordinary" != status { return }
        self.status = "my-note"
        self.refresh();
    }

    func onSwipeUp(_ ges:UIGestureRecognizer) {
        if "ordinary" != status { return }
        self.status = "ordinary"
        self.refresh();
    }

    func onToggleMyNote(_ sender:UIControl!) {
        print("toggleMyNote")
        self.status = "ordinary"
        self.refresh()
    }
    
    static func setHtmlText(_ html:String, on:UITextView) {
        let PREFIX:String = "<span style='font-size:18px;AppleGothic;font-family:Apple SD Gothic Neo;font-weight:400;font-size:18px;'>"
        let SUFFIX:String = "</span>"
        
        do {
            let myStr:String = PREFIX+html+SUFFIX
            let str = try NSMutableAttributedString(data: myStr.data(using: String.Encoding.unicode, allowLossyConversion: true)!, options: [ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)

            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineSpacing = -2.0
            str.addAttribute(NSParagraphStyleAttributeName, value:paraStyle, range:NSMakeRange(0, str.length))
            
            on.attributedText = str
        } catch {
            print(error)
        }
    }
    
}
