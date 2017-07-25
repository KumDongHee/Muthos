//
//  TooltipHeader.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 21..
//
//
import UIKit
import Foundation

class TooltipHeader: UITableViewHeaderFooterView, CollapsableTableViewSectionHeaderProtocol {

    @IBOutlet weak var sectionTitleLabel: UILabel!
    @IBOutlet weak var arrowImgView: UIImageView!
    
    var interactionDelegate: CollapsableTableViewSectionHeaderInteractionProtocol!
    
    func radians(_ degrees: Double) -> Double {
        return Double.pi * degrees / 180.0
    }
    
    fileprivate var isRotating = false
    
    func open(_ animated: Bool) {
        
        if animated && !isRotating {
            
            isRotating = true
            
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.allowUserInteraction, .curveLinear], animations: { () -> Void in
                self.arrowImgView.transform = CGAffineTransform.identity
                }, completion: { (finished) -> Void in
                    self.isRotating = false
            })
        } else {
            layer.removeAllAnimations()
            arrowImgView.transform = CGAffineTransform.identity
            isRotating = false
        }
    }
    
    func close(_ animated: Bool) {
        
        if animated && !isRotating {
            
            isRotating = true
            
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.allowUserInteraction, .curveLinear], animations: { () -> Void in
                self.arrowImgView.transform = CGAffineTransform(rotationAngle: CGFloat(self.radians(180.0)))
                }, completion: { (finished) -> Void in
                    self.isRotating = false
            })
        } else {
            layer.removeAllAnimations()
            arrowImgView.transform = CGAffineTransform(rotationAngle: CGFloat(radians(180.0)))
            isRotating = false
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesEnded(touches, with: event)
        
        guard let touch = touches.first else {
            return
        }
        
        interactionDelegate?.userTappedView(self, atPoint: touch.location(in: self))
    }
}
