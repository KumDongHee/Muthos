//
//  ArcView.swift
//  Muthos
//
//  Created by shining on 2016. 9. 23..
//
//

import UIKit

let π:CGFloat = CGFloat(Double.pi)

@IBDesignable

class ArcView:UIView {
    @IBInspectable var borderWidth: CGFloat = 7
    @IBInspectable var rate : CGFloat = 0.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable var lineCapStyle: CGLineCap = CGLineCap.square
    var borderColor:UIColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.3)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.doInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        self.doInit()
    }

    fileprivate func doInit() {
        backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect:CGRect)
    {
//        let path = UIBezierPath(ovalInRect: rect)
//        UIColor.greenColor().setFill()
//        path.fill()
        let center:CGPoint = CGPoint(x: rect.midX, y: rect.midY)
        let radius: CGFloat = min(bounds.width, bounds.height)
        drawBackgroundCircle(center, radius: radius)
        let startAngle: CGFloat = 3 * π / 2
        let endAngle: CGFloat = 2 * π * rate + startAngle
        let path = UIBezierPath(arcCenter: center,
                                radius: radius/2 - borderWidth/2,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: true)
        
        // 6
        path.lineWidth = borderWidth
        path.lineCapStyle = lineCapStyle
        tintColor.setStroke()
        path.stroke()
    }
    
    func drawBackgroundCircle(_ center:CGPoint, radius:CGFloat) {
        let path = UIBezierPath(arcCenter: center,
                                radius: radius/2 - borderWidth/2,
                                startAngle: 0,
                                endAngle: 2 * π,
                                clockwise: true)
        
        path.lineWidth = borderWidth
        borderColor.setStroke()
        path.stroke()
    }
}
