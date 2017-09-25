//
//  SituationItem.swift
//  muthos
//
//  Created by KumDongHee on 2017. 9. 25..
//
//

import UIKit
import SwiftyJSON

protocol SituationItemDelegate : class {
    func SituationItemDidTapped(item:SituationItem, quote:JSON)
}

class SituationItem: UIView {
    
    var quote:JSON?
    var playMode:String? = ""
    
    weak var delegate:SituationItemDelegate?
    
    
    init(quote: JSON) {
        super.init(frame: CGRect())
        self.quote = quote
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SituationItem.tapped(_:))))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    func tapped(_ ges:UIGestureRecognizer) {
        guard let delegate = delegate else { return }
        delegate.SituationItemDidTapped(item: self, quote: quote!)
    }

}
