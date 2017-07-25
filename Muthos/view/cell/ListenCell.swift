//
//  ListenCell.swift
//  Muthos
//
//  Created by Youngjune Kwon on 2016. 3. 13..
//
//

import UIKit
import SwiftyJSON
import SDWebImage
import SwiftAnimations

class ListenCell: UITableViewCell {
    @IBOutlet weak var leftView: UIView!
    @IBOutlet weak var rightView: UIView!
    @IBOutlet weak var narrationView: UIView!
    @IBOutlet weak var narrationWrap: UIView!
    @IBOutlet weak var narrationTalk: UITextView!
    
    @IBOutlet weak var leftPic: UIImageView!
    @IBOutlet weak var leftName: UILabel!
    @IBOutlet weak var leftTalk: UITextView!
    @IBOutlet weak var leftBallon: UIView!
    @IBOutlet weak var leftTriangle: TriangleView!
    @IBOutlet weak var leftHighlightedTriangle: TriangleView!
    @IBOutlet weak var leftHighlighted: UIView!

    @IBOutlet weak var rightPic: UIImageView!
    @IBOutlet weak var rightName: UILabel!
    @IBOutlet weak var rightTalk: UITextView!
    @IBOutlet weak var rightBallon: UIView!
    @IBOutlet weak var rightTriangle: TriangleView!
    @IBOutlet weak var rightHighlightedTriangle: TriangleView!
    @IBOutlet weak var rightHighlighted: UIView!

    let PADDING_WIDTH:CGFloat = 7.5
    let PADDING_HEIGHT:CGFloat = 5
    let PADDING_HEIGHT_NARRATION:CGFloat = 15
    let MARGIN_TOP:CGFloat = 20
    let MAX_WIDTH:CGFloat = 225
    let MULTIPLY:CGFloat = 4
    let CORNER_RADIUS:CGFloat = 3
    
    static var BALLON_DEFAULT:CGRect = CGRect(x: 71, y: 26.75, width: 600, height: 50)
    static var NARRATION_DEFAULT:CGRect = CGRect(x: 10, y: 10, width: 576, height: 70)
    let HORIZONTAL_MARGIN_OF_BALLON:CGFloat = 30
    let HORIZONTAL_MARGIN_OF_NARRATION:CGFloat = 10
    let PIC_DEFAULT:CGRect = CGRect(x: 12, y: 10, width: 49, height: 49)
    let NAME_DEFAULT:CGRect = CGRect(x: 69,y: 10,width: 137,height: 15)

    let TENSION:CGFloat = 4
    
    var talkSize:CGSize = CGSize.zero

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initBallonDefault()
    }
    
    func initBallonDefault() {
        ListenCell.BALLON_DEFAULT.size.width = self.frame.size.width - ListenCell.BALLON_DEFAULT.minX - HORIZONTAL_MARGIN_OF_BALLON
        ListenCell.NARRATION_DEFAULT.size.width = UIScreen.main.bounds.size.width - ListenCell.NARRATION_DEFAULT.minX - HORIZONTAL_MARGIN_OF_NARRATION
    }
    
    func changeSize(_ rect:CGRect, width:CGFloat, height:CGFloat) -> CGRect {
        return CGRect(x: rect.origin.x, y: rect.origin.y, width: width, height: height)
    }
    
    func changeSizeAndAlignRight(_ rect:CGRect, width:CGFloat, height:CGFloat) -> CGRect {
        return CGRect(x: rect.maxX - width, y: rect.origin.y, width: width, height: height)
    }

    func alignLeftOn(_ rect:CGRect, left:CGFloat) -> CGRect {
        return CGRect(x: left, y: rect.origin.y, width: rect.size.width, height: rect.size.height)
    }
    
    func alignRightOn(_ rect:CGRect, right:CGFloat) -> CGRect {
        return CGRect(x: right - rect.size.width, y: rect.origin.y, width: rect.size.width, height: rect.size.height)
    }
    
    func determineHeightFor(_ dialog:JSON) -> CGFloat {
        if let s = dialog["translation"].string {
            leftTalk.frame = changeSize(leftTalk.frame, width:ListenCell.BALLON_DEFAULT.size.width - PADDING_WIDTH * 2, height:ListenCell.BALLON_DEFAULT.size.height)
            narrationTalk.frame = changeSize(narrationTalk.frame, width:ListenCell.NARRATION_DEFAULT.size.width - PADDING_WIDTH * 2, height:ListenCell.NARRATION_DEFAULT.size.height - PADDING_HEIGHT * 2)
            leftTalk.text = s
            narrationTalk.text = s
            self.forceSetFont()
            leftTalk.sizeToFit()
            narrationTalk.sizeToFit()
            
            if dialog["name"] == "" {
                let size:CGSize = narrationTalk.bounds.size
                return size.height + PADDING_HEIGHT_NARRATION * 2
            }
            else {
                let size:CGSize = leftTalk.bounds.size
                return size.height + PADDING_HEIGHT * 2 + MARGIN_TOP
            }
            
        }
        return 0
    }
    
    func clear() {
        
    }
    
    func setModel(_ dialog:JSON, speakers:JSON) {
        self.initBallonDefault()
        self.selectionStyle = .none
        self.initComponents()
        self.setNameAndPic(dialog, speakers:speakers)

        if let s = dialog["translation"].string {
            leftTalk.frame = changeSize(leftTalk.frame, width:ListenCell.BALLON_DEFAULT.size.width - PADDING_WIDTH * 2, height:ListenCell.BALLON_DEFAULT.size.height)
            rightTalk.frame = changeSize(rightTalk.frame, width:ListenCell.BALLON_DEFAULT.size.width - PADDING_WIDTH * 2, height:ListenCell.BALLON_DEFAULT.size.height)
            narrationTalk.frame = changeSize(narrationTalk.frame, width:ListenCell.NARRATION_DEFAULT.size.width - PADDING_WIDTH * 2, height:ListenCell.NARRATION_DEFAULT.size.height - PADDING_HEIGHT * 2)
            leftTalk.text = s
            rightTalk.text = s
            narrationTalk.text = s
            self.forceSetFont()
            leftTalk.sizeToFit()
            rightTalk.sizeToFit()
            narrationTalk.sizeToFit()

            self.talkSize = leftTalk.frame.size
            self.alignBallons()
        }
        
    }
    
    func forceSetFont() {
        leftTalk.font = UIFont.systemFont(ofSize: 16)
        rightTalk.font = UIFont.systemFont(ofSize: 16)
        narrationTalk.font = UIFont.systemFont(ofSize: 16)
        narrationTalk.textColor = UIColor(white:1, alpha:1)
    }

    func alignBallons(_ tension:CGFloat) {
        let area:CGSize = CGSize(width: (self.talkSize.width + self.PADDING_WIDTH * 2) + tension, height: self.talkSize.height)
        
        leftBallon.frame = changeSize(ListenCell.BALLON_DEFAULT, width:area.width, height:area.height)
        rightBallon.frame = alignRightOn(leftBallon.frame, right:self.frame.size.width - ListenCell.BALLON_DEFAULT.minX)
        
        leftHighlighted.frame = changeSize(leftHighlighted.frame, width:area.width, height:area.height)
        rightHighlighted.frame = changeSize(rightHighlighted.frame, width:area.width, height:area.height)

        narrationWrap.frame = changeSize(ListenCell.NARRATION_DEFAULT, width:ListenCell.NARRATION_DEFAULT.width+tension, height:narrationTalk.height)
    }
    
    func alignBallons() {
        self.alignBallons(0)
    }
    
    func setNameAndPic(_ dialog:JSON, speakers:JSON) {
        if let s = dialog["name"].string {
            leftName.text = s
            rightName.text = s
            guard speakers[s].error == nil else {return}
            let p:JSON = speakers[s]
            if let i = p["pic"].string {
                leftPic.sd_setImage(with: URL(string:i))
                rightPic.sd_setImage(with: URL(string:i))
            }
        }
        
        leftView.isHidden = true
        rightView.isHidden = true
        narrationView.isHidden = true
        
        if dialog["name"].string == "" {
            narrationView.isHidden = false
        }
        else if dialog["name"].string == speakers["user"].string {
            rightView.isHidden = false
        }
        else {
            leftView.isHidden = false
        }
    }
    
    func initComponents() {
        leftBallon.translatesAutoresizingMaskIntoConstraints = true
        rightBallon.translatesAutoresizingMaskIntoConstraints = true
        narrationWrap.translatesAutoresizingMaskIntoConstraints = true
        narrationTalk.translatesAutoresizingMaskIntoConstraints = true
        
        leftPic.layer.cornerRadius = leftPic.frame.size.width / 2
        leftPic.layer.masksToBounds = true
        rightPic.layer.cornerRadius = rightPic.frame.size.width / 2
        rightPic.layer.masksToBounds = true

        narrationWrap.layer.cornerRadius = CORNER_RADIUS
        leftBallon.layer.cornerRadius = CORNER_RADIUS
        leftBallon.layer.masksToBounds = true
        rightBallon.layer.cornerRadius = CORNER_RADIUS
        rightBallon.layer.masksToBounds = true
        
        leftTriangle.point = TriangleView.PointPosition.topLeft
        rightTriangle.point = TriangleView.PointPosition.topRight

        leftHighlightedTriangle.point = TriangleView.PointPosition.topLeft
        rightHighlightedTriangle.point = TriangleView.PointPosition.topRight

        leftTriangle.tintColor = leftBallon.backgroundColor
        rightTriangle.tintColor = rightBallon.backgroundColor

        leftTalk.translatesAutoresizingMaskIntoConstraints = true
        rightTalk.translatesAutoresizingMaskIntoConstraints = true
        leftHighlighted.translatesAutoresizingMaskIntoConstraints = true
        rightHighlighted.translatesAutoresizingMaskIntoConstraints = true

        self.leftHighlightedTriangle.tintColor = self.leftHighlighted.backgroundColor
        self.rightHighlightedTriangle.tintColor = self.rightHighlighted.backgroundColor
        self.leftTriangle.tintColor = self.leftBallon.backgroundColor
        self.rightTriangle.tintColor = self.rightBallon.backgroundColor
    }
    
    func setPlaying(_ playing: Bool) {
        animate {
            if playing {
                self.leftHighlighted.layer.opacity = 1
                self.rightHighlighted.layer.opacity = 1
                self.leftHighlightedTriangle.layer.opacity = 1
                self.rightHighlightedTriangle.layer.opacity = 1
            }
            else {
                self.leftHighlighted.layer.opacity = 0
                self.rightHighlighted.layer.opacity = 0
                self.leftHighlightedTriangle.layer.opacity = 0
                self.rightHighlightedTriangle.layer.opacity = 0
            }

            var textColor:UIColor?
            if playing {
                textColor = UIColor(white:1, alpha:1)
            }
            else {
                textColor = UIColor(white:0, alpha:1)
            }
            self.leftTalk.textColor = textColor
            self.rightTalk.textColor = textColor
            
            self.rightTriangle.setNeedsDisplay()
            self.leftTriangle.setNeedsDisplay()

            self.rightHighlightedTriangle.setNeedsDisplay()
            self.leftHighlightedTriangle.setNeedsDisplay()

            }.withDuration(0.15).withOptions(.curveEaseOut).completion({(finish) -> Void in
            })
    }
    
    func setAnchorPoint(_ anchorPoint: CGPoint, forView view: UIView) {
        var newPoint = CGPoint(x: view.bounds.size.width * anchorPoint.x, y: view.bounds.size.height * anchorPoint.y)
        var oldPoint = CGPoint(x: view.bounds.size.width * view.layer.anchorPoint.x, y: view.bounds.size.height * view.layer.anchorPoint.y)
        
        newPoint = newPoint.applying(view.transform)
        oldPoint = oldPoint.applying(view.transform)
        
        var position = view.layer.position
        position.x -= oldPoint.x
        position.x += newPoint.x
        
        position.y -= oldPoint.y
        position.y += newPoint.y
        
        view.layer.position = position
        view.layer.anchorPoint = anchorPoint
    }
    
    func playAnimation() {
        self.perform(#selector(ListenCell.doAnimation), with: nil, afterDelay: 0.2)
    }

    func moveHorizontally(_ rect:CGRect, d:CGFloat) -> CGRect {
        return CGRect(x: rect.origin.x+d, y: rect.origin.y, width: rect.size.width, height: rect.size.height)
    }
    
    func doAnimation() {
        let WITH_TRIANGLE:CGFloat = 6
        let leftTriangleOrigin:CGRect = leftTriangle.frame
        let rightTriangleOrigin:CGRect = rightTriangle.frame
        
        let narrationOrigin:CGRect = narrationWrap.frame
        
        self.leftBallon.frame = moveHorizontally(changeSize(self.leftBallon.frame, width:0, height:0), d:WITH_TRIANGLE * -1)
        self.rightBallon.frame = alignRightOn(self.leftBallon.frame, right:self.frame.size.width - ListenCell.BALLON_DEFAULT.minX + WITH_TRIANGLE)

        self.narrationWrap.frame = changeSize(self.narrationWrap.frame, width:0, height:0)

        self.leftPic.transform = CGAffineTransform(translationX: 0 - self.leftPic.frame.minX, y: 0)
        self.rightPic.transform = CGAffineTransform(translationX: self.frame.maxX - self.rightPic.frame.maxX, y: 0)
        
        self.leftPic.layer.opacity = 0
        self.rightPic.layer.opacity = 0

        self.leftName.layer.opacity = 0
        self.rightName.layer.opacity = 0
        
        self.leftTalk.isHidden = true
        self.rightTalk.isHidden = true
        self.narrationTalk.isHidden = true
        
        self.leftTriangle.isHidden = true
        self.rightTriangle.isHidden = true
        self.leftHighlightedTriangle.isHidden = true
        self.rightHighlightedTriangle.isHidden = true
        
        self.leftTriangle.frame = changeSize(leftTriangleOrigin, width:0, height:leftTriangleOrigin.size.height)
        self.rightTriangle.frame = alignRightOn(changeSize(rightTriangleOrigin, width:0, height:rightTriangleOrigin.size.height), right:rightTriangleOrigin.maxX)
        self.leftHighlightedTriangle.frame = changeSize(leftTriangleOrigin, width:0, height:leftTriangleOrigin.size.height)
        self.rightHighlightedTriangle.frame = alignRightOn(changeSize(rightTriangleOrigin, width:0, height:rightTriangleOrigin.size.height), right:rightTriangleOrigin.maxX)
        
        animate {
            self.leftPic.transform = CGAffineTransform.identity
            self.rightPic.transform = CGAffineTransform.identity
            self.leftPic.layer.opacity = 1
            self.rightPic.layer.opacity = 1
            
            }.withOptions(.curveEaseOut).withDuration(0.2).thenAnimate({_ -> Void in
                self.leftBallon.frame = self.changeSize(self.leftBallon.frame, width:1, height:self.talkSize.height)
                self.rightBallon.frame = self.changeSize(self.rightBallon.frame, width:1, height:self.talkSize.height)
                self.leftName.layer.opacity = 1
                self.rightName.layer.opacity = 1
            }).withOptions(.curveEaseOut).withDuration(0.05).thenAnimate({(finish) -> Void in
                self.leftTriangle.isHidden = false
                self.rightTriangle.isHidden = false
                self.leftHighlightedTriangle.isHidden = false
                self.rightHighlightedTriangle.isHidden = false

                self.leftTriangle.frame = leftTriangleOrigin
                self.rightTriangle.frame = self.alignRightOn(rightTriangleOrigin, right:rightTriangleOrigin.maxX)
                self.leftHighlightedTriangle.frame = leftTriangleOrigin
                self.rightHighlightedTriangle.frame = self.alignRightOn(rightTriangleOrigin, right:rightTriangleOrigin.maxX)

                
                self.alignBallons(self.TENSION)
            }).withOptions(.curveEaseOut).withDuration(0.15).thenAnimate({(finish) -> Void in
                self.alignBallons()
            }).withOptions(.curveEaseOut).withDuration(0.3).completion({(finish) -> Void in
                self.alignBallons()
                self.leftTalk.isHidden = false
                self.rightTalk.isHidden = false
            })

        animate {
            self.narrationWrap.frame = self.changeSize(self.narrationWrap.frame, width:1, height:narrationOrigin.height)
            }.withOptions(.curveEaseOut).withDuration(0.05).thenAnimate({_ -> Void in
                self.narrationWrap.frame = self.changeSize(self.narrationWrap.frame, width:narrationOrigin.width+self.TENSION, height:narrationOrigin.height)
            }).withOptions(.curveEaseOut).withDuration(0.15).thenAnimate({(finish) -> Void in
                self.narrationWrap.frame = self.changeSize(self.narrationWrap.frame, width:narrationOrigin.width, height:narrationOrigin.height)
            }).withOptions(.curveEaseOut).withDuration(0.3).completion({(finish) -> Void in
                self.narrationTalk.isHidden = false
            })

        
        self.isHidden = false
    }
    
    func alignTextVerticalInTextView(_ textView :UITextView) {
        let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: CGFloat(MAXFLOAT)))
        
        var topoffset = (textView.bounds.size.height - size.height * textView.zoomScale) / 2.0
        topoffset = topoffset < 0.0 ? 0.0 : topoffset
        
        textView.contentOffset = CGPoint(x: 0, y: -topoffset)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
