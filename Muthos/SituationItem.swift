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
    let quoteView:UITextView = UITextView()
    
    let BACKGROUND_STANDARD_WIDTH : CGFloat = 375
    let BACKGROUND_STANDARD_HEIGHT : CGFloat = 667
    
    var fontSize : Int = 18
    
    var textcolor = "white"
    
    weak var delegate:SituationItemDelegate?
    
    
    init(quote: JSON, playmode: String) {
        super.init(frame: CGRect())
        fontSize = Int(18 * pow(UIScreen.main.bounds.size.width / BACKGROUND_STANDARD_WIDTH,1/2))
        self.quote = quote
        self.playMode = playmode
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
    
    func showDictationResult() {
        let text:String = quote!["text"].string!
        let dictations = quote!["dictation"].string!
        var html:String = BookController.getDictationResultOf(text, dictations: dictations)
        html = "<span style='color:\(textcolor);font-size:\(fontSize)'>" + html + "</span>"
        quoteView.setHtmlText(html)
        quoteView.sizeToFit()
    }
    
    func getQuoteText() -> String {
        return BookController.getQuoteTextOf(dialog: self.quote!, params: self.quote!, playMode: playMode!)
    }
    func getDictationText() -> String {
        return BookController.getDictationTextOf(self.quote!["text"].string!, dictations:self.quote!["dictation"].string!)
    }

}
