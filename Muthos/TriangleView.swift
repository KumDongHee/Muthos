//
//  TriangleView.swift
//  Muthos
//
//  Created by Youngjune Kwon on 2016. 3. 23..
//
//

import UIKit

class TriangleView: UIView {

    enum PointPosition {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        case leftDown
        case rightDown
        case leftUp
        case rightUp
        case downCenter
        case upCenter
    }
    
    var point:PointPosition = PointPosition.topLeft
    var baseline:CGFloat = -1
    
    override func draw(_ rect:CGRect)
    {
        print("draw Triangle, "+String(describing: point))
        
        let ctx:CGContext = UIGraphicsGetCurrentContext()!

        ctx.setFillColor(UIColor.clear.cgColor)
        ctx.fill(rect)
        
        ctx.beginPath()
        if PointPosition.topLeft == point {
            ctx.move   (to: CGPoint(x: rect.maxX, y: rect.maxY));
            ctx.addLine(to: CGPoint(x: baseline >= 0 ? rect.maxX - baseline : rect.minX, y: rect.maxY));
            ctx.addLine(to: CGPoint(x: rect.minX, y: rect.minY));
        }
        else if PointPosition.topRight == point{
            ctx.move   (to: CGPoint(x: rect.minX, y: rect.maxY));
            ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.minY));
            ctx.addLine(to: CGPoint(x: baseline >= 0 ? rect.minX + baseline : rect.maxX, y: rect.maxY));
        }
        else if PointPosition.bottomLeft == point{
            ctx.move   (to: CGPoint(x: rect.maxX, y: rect.minY));
            ctx.addLine(to: CGPoint(x: baseline >= 0 ? rect.maxX - baseline : rect.minX, y: rect.minY));
            ctx.addLine(to: CGPoint(x: rect.minX, y: rect.maxY));
        }
        else if PointPosition.bottomRight == point {
            ctx.move   (to: CGPoint(x: baseline >= 0 ? rect.minX + baseline : rect.maxX, y: rect.minY));
            ctx.addLine(to: CGPoint(x: rect.minX, y: rect.minY));
            ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY));
        }
        else if PointPosition.leftDown == point {
            ctx.move   (to: CGPoint(x: rect.maxX, y: rect.minY));
            ctx.addLine(to: CGPoint(x: rect.maxX, y: baseline >= 0 ? rect.minY + baseline : rect.maxY));
            ctx.addLine(to: CGPoint(x: rect.minX, y: rect.maxY));
        }
        else if PointPosition.rightDown == point {
            ctx.move   (to: CGPoint(x: rect.minX, y: rect.minY));
            ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY));
            ctx.addLine(to: CGPoint(x: rect.minX, y: baseline >= 0 ? rect.minY + baseline : rect.maxY));
        }
        else if PointPosition.leftUp == point {
            ctx.move   (to: CGPoint(x: rect.maxX, y: baseline >= 0 ? rect.maxY - baseline : rect.minY));
            ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY));
            ctx.addLine(to: CGPoint(x: rect.minX, y: rect.minY));
        }
        else if PointPosition.rightUp == point {
            ctx.move   (to: CGPoint(x: rect.minX, y: baseline >= 0 ? rect.maxY - baseline : rect.minY));
            ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.minY));
            ctx.addLine(to: CGPoint(x: rect.minX, y: rect.maxY));
        }
        else if PointPosition.downCenter == point {
            ctx.move   (to: CGPoint(x: rect.maxX, y: rect.minY));
            ctx.addLine(to: CGPoint(x: rect.minX, y: rect.minY));
            ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY));
        }
        else if PointPosition.upCenter == point {
            ctx.move   (to: CGPoint(x: rect.minX, y: rect.maxY));
            ctx.addLine(to: CGPoint(x: rect.midX, y: rect.minY));
            ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY));
        }
        ctx.closePath();
        
        ctx.setFillColor(self.tintColor.cgColor)
        ctx.fillPath()
    }
}
