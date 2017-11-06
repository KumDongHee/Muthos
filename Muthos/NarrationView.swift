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
    
    var backgroundShadow : UIImageView = UIImageView(image: UIImage(named: "talk_bg_sh_top_narration"))
    
    let BACKGROUND_OFFSET : CGFloat = 100
    let PADDING_X : CGFloat = 12
    let PADDING_Y : CGFloat = 12
    
    override init(quote: JSON, playmode: String) {
        super.init(quote : quote, playmode: playmode)
        
        fontSize = Int(20 * pow(UIScreen.main.bounds.size.width / BACKGROUND_STANDARD_WIDTH,1/2))
        textcolor = "white"
        
        quoteView.frame = CGRect(x:PADDING_X, y:PADDING_Y, width:UIScreen.main.bounds.size.width - 2 * PADDING_X, height:10000)
        
        
        let text:String = self.getQuoteText()
        
        quoteView.setHtmlText("<span style='color:white;font-size:"+String(fontSize)+"'>"+text+"</span>")
        quoteView.isEditable = false
        quoteView.isUserInteractionEnabled = false
        quoteView.backgroundColor = UIColor.clear
        quoteView.sizeToFit()
        
        
        self.frame = CGRect(x:0, y:0, width:UIScreen.main.bounds.size.width, height:PADDING_Y + quoteView.frame.size.height)
        self.layer.masksToBounds = false
        
        adjustShadow();
        
        self.addSubview(backgroundShadow)
        self.addSubview(quoteView)
    }
    
    func adjustShadow() {
        backgroundShadow.frame = CGRect(x: 0, y: PADDING_Y + quoteView.frame.size.height + BACKGROUND_OFFSET - backgroundShadow.frame.size.height, width: UIScreen.main.bounds.size.width, height: backgroundShadow.frame.size.height)
        
    }
    
    override func showDictationResult() {
        quoteView.frame = CGRect(x:PADDING_X, y:PADDING_Y, width:UIScreen.main.bounds.size.width - 2 * PADDING_X, height:10000)
        super.showDictationResult()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
