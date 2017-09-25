//
//  NarrationView.swift
//  muthos
//
//  Created by KumDongHee on 2017. 9. 25..
//
//

import UIKit
import SwiftyJSON

class NarrationView: SituationItem {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    var narrTextView : UITextView = UITextView()
    var backgroundShadow : UIImageView = UIImageView(image: UIImage(named: "talk_bg_sh_top_narration"))
    
    let PADDING_X : CGFloat = 12
    let PADDING_Y : CGFloat = 20
    
    override init(quote: JSON) {
        super.init(quote : quote)
        
        self.frame = CGRect(x:0, y:0, width:UIScreen.main.bounds.size.width, height:10000)
        
        narrTextView.frame = CGRect(x:PADDING_X, y:PADDING_Y, width:self.frame.size.width - 2 * PADDING_X, height:10000)
        
        
        let text:String = BookController.getQuoteTextOf(dialog: quote, params: quote, playMode: self.playMode!)
        
        var fontSize:Int = 20
        
        if quote["font-size"].error == nil {
            let fs:Int = quote["font-size"].intValue
            if fs > 0 { fontSize = fs }
        }
        
        narrTextView.setBalloonHtmlText("<span style='color:white;font-size:"+String(fontSize)+"'>"+text+"</span>")
        narrTextView.isEditable = false
        narrTextView.isUserInteractionEnabled = false
        narrTextView.backgroundColor = UIColor.clear
        narrTextView.sizeToFit()
        
        backgroundShadow.frame = CGRect(x: 0, y: narrTextView.height - backgroundShadow.height, width: self.frame.size.width, height: backgroundShadow.frame.size.height)
        
        self.addSubview(backgroundShadow)
        self.addSubview(narrTextView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
