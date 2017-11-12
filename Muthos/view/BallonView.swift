//
//  BallonView.swift
//  Muthos
//
//  Created by Youngjune Kwon on 2016. 3. 3..
//
//

import UIKit
import SwiftyJSON



class BallonView:SituationItem {
    
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
    let recognizedTextView:UITextView = UITextView()
    let recognizedBackground:UIView = UIView()
    let quoteBackground:UIView = UIView()
    var edge:TriangleEdge = TriangleEdge.bottomLeft
    var edgeEnd:CGPoint = CGPoint()
    static let MARGIN:CGFloat = 3
    static let PADDING_MYNOTE:CGFloat = 15
    
    override init(quote: JSON, playmode: String) {
        super.init(quote : quote, playmode: playmode)
        
        textcolor = "black"
        
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.4
        self.layer.shadowRadius = 2
        self.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        
        quoteView.isEditable = false
        quoteView.isUserInteractionEnabled = false
        quoteView.backgroundColor = UIColor.clear
        
        quoteView.frame = CGRect(x: PADDING_WIDTH+X_MOVE, y: 0, width: UIScreen.main.bounds.size.width * 2 / 3, height: 40)
        let w:Int = self.quote!["position"]["width"].intValue
        if w > 0 {
            quoteView.frame.size.width = CGFloat(w)
        }
        
        quoteView.setHtmlText(self.getQuoteText())
        quoteView.sizeToFit()
        quoteBackground.addSubview(quoteView)
        
        quoteBackground.layer.cornerRadius = 3
        quoteBackground.layer.masksToBounds = true
        quoteBackground.backgroundColor = UIColor.white
        quoteBackground.frame = CGRect(x: 0, y: 0, width: quoteView.width+PADDING_WIDTH*2, height: quoteView.height)

        
        let CGleft = CGFloat(quote["position"]["left"].floatValue)
        let CGtop = CGFloat(quote["position"]["top"].floatValue)
        var x : CGFloat = CGleft * UIScreen.main.bounds.size.width / BACKGROUND_STANDARD_WIDTH
        var y = CGtop * UIScreen.main.bounds.size.width / BACKGROUND_STANDARD_WIDTH
            - ( BACKGROUND_STANDARD_HEIGHT * UIScreen.main.bounds.size.width / BACKGROUND_STANDARD_WIDTH - UIScreen.main.bounds.size.height ) / 2
        
        x = CGleft < 0 ? UIScreen.main.bounds.size.width + x - quoteBackground.width : x
        y = CGtop < 0 ? UIScreen.main.bounds.size.height + y - quoteBackground.height : y
        
        self.frame = CGRect(x: x, y: y , width: quoteBackground.width, height: quoteBackground.height + triangle.height)

        
        addSubview(quoteBackground)
        
        initEdge()
        initTriangleView()
        
        addSubview(triangle)
        
        if TriangleEdge.bottomLeft == edge || TriangleEdge.bottomRight == edge {
            triangle.frame.origin.y = quoteBackground.height
        }
    }
    
    func changeToAnswerBallon(recognized : String, flexibility : JSON) -> Int {
        
        let json:JSON = BookController.evaluateSentence(self.getQuoteText(), desc: recognized, flexibility:flexibility)
        quoteView.setHtmlText(json["orig"].stringValue)
        
        recognizedTextView.isEditable = false
        recognizedTextView.isUserInteractionEnabled = false
        recognizedTextView.backgroundColor = UIColor.clear
        
        recognizedTextView.frame = CGRect(x: PADDING_WIDTH+X_MOVE, y: 0, width: UIScreen.main.bounds.size.width * 2 / 3, height: 40)
        
        recognizedTextView.setHtmlText(json["desc"].stringValue)
        recognizedTextView.sizeToFit()
        recognizedBackground.frame = CGRect(x: 0, y: quoteView.frame.size.height, width: recognizedTextView.width+PADDING_WIDTH*2, height: recognizedTextView.height)
        recognizedBackground.backgroundColor = UIColor.yellow
        recognizedBackground.addSubview(recognizedTextView)
        
        quoteBackground.frame.size.height += recognizedTextView.frame.size.height
        
        recognizedBackground.frame.size.width = max(recognizedBackground.frame.size.width, quoteBackground.frame.size.width)
        quoteBackground.frame.size.width = recognizedBackground.frame.size.width
        
        quoteBackground.addSubview(recognizedBackground)
        
        self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y - recognizedBackground.frame.height / 2, width: quoteBackground.width, height: quoteBackground.height + triangle.height)
        
        
        initTriangleView()
        triangle.tintColor = UIColor.yellow
        
        if TriangleEdge.bottomLeft == edge || TriangleEdge.bottomRight == edge {
            triangle.frame.origin.y = quoteBackground.height
        }
        
        return max(json["grade"].intValue, 1) as Int
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func isEmptyEdgeEnd() -> Bool {
        return edgeEnd.x == 0 && edgeEnd.y == 0
    }
    
    func initEdge() {
        edge = .bottomLeft
        edgeEnd.x = 0
        edgeEnd.y = 0
        
        guard let quote = quote else { return }
        guard quote["position"]["tail"].error == nil else { return }
        
        let tailString = quote["position"]["tail"].stringValue
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
    
    let PADDING_WIDTH:CGFloat = 8
    let X_MOVE:CGFloat = 1
    
    override func showDictationResult() {
        super.showDictationResult()
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
    
    override func getQuoteText() -> String {
        return BookController.getQuoteTextOf(dialog: self.quote!, params: self.quote!, playMode: playMode!, hideColor:"white")
    }
    
}

extension UITextView {
    
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
