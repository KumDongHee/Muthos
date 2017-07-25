//
//  UIView.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 20..
//
//

import UIKit

protocol UIViewLoading {}
extension UIView : UIViewLoading {}

extension UIViewLoading where Self : UIView {
    
    // note that this method returns an instance of type `Self`, rather than UIView
    static func loadFromNib() -> Self {
        let nibName = "\(self)".characters.split{$0 == "."}.map(String.init).last!
        let nib = UINib(nibName: nibName, bundle: nil)
        return nib.instantiate(withOwner: self, options: nil).first as! Self
    }
    
}

extension UIView{
    var width:      CGFloat { return self.frame.size.width }
    var height:     CGFloat { return self.frame.size.height }
    var size:       CGSize  { return self.frame.size}
    
    var origin:     CGPoint { return self.frame.origin }
    var x:          CGFloat { return self.frame.origin.x }
    var y:          CGFloat { return self.frame.origin.y }
    var centerX:    CGFloat { return self.center.x }
    var centerY:    CGFloat { return self.center.y }
    
    var left:       CGFloat { return self.frame.origin.x }
    var right:      CGFloat { return self.frame.origin.x + self.frame.size.width }
    var top:        CGFloat { return self.frame.origin.y }
    var bottom:     CGFloat { return self.frame.origin.y + self.frame.size.height }
    
    func setWidth(_ width:CGFloat)
    {
        self.frame.size.width = width
    }
    
    func setHeight(_ height:CGFloat)
    {
        self.frame.size.height = height
    }
    
    func setSize(_ size:CGSize)
    {
        self.frame.size = size
    }
    
    func setOrigin(_ point:CGPoint)
    {
        self.frame.origin = point
    }
    
    func setX(_ x:CGFloat) //only change the origin x
    {
        self.frame.origin = CGPoint(x: x, y: self.frame.origin.y)
    }
    
    func setY(_ y:CGFloat) //only change the origin x
    {
        self.frame.origin = CGPoint(x: self.frame.origin.x, y: y)
    }
    
    func setCenterX(_ x:CGFloat) //only change the origin x
    {
        self.center = CGPoint(x: x, y: self.center.y)
    }
    
    func setCenterY(_ y:CGFloat) //only change the origin x
    {
        self.center = CGPoint(x: self.center.x, y: y)
    }
    
    func roundCorner(_ radius:CGFloat)
    {
        self.layer.cornerRadius = radius
    }
    
    func setTop(_ top:CGFloat)
    {
        self.frame.origin.y = top
    }
    
    func setLeft(_ left:CGFloat)
    {
        self.frame.origin.x = left
    }
    
    func setRight(_ right:CGFloat)
    {
        self.frame.origin.x = right - self.frame.size.width
    }
    
    func setBottom(_ bottom:CGFloat)
    {
        self.frame.origin.y = bottom - self.frame.size.height
    }
    
    func circle() -> UIView {
        self.layer.cornerRadius = self.frame.size.height/2.0
        self.layer.masksToBounds = true
        return self
    }
    
    func borderWith(_ color:UIColor, width:CGFloat) -> UIView {
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
        return self
    }
    
    class func renderUIViewToImage(viewToBeRendered:UIView?) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions((viewToBeRendered?.bounds.size)!, false, 0.0)
        viewToBeRendered!.drawHierarchy(in: viewToBeRendered!.bounds, afterScreenUpdates: true)
        viewToBeRendered!.layer.render(in: UIGraphicsGetCurrentContext()!)
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage!
    }
}
