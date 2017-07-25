//
//  SummaryCont.swift
//  muthos
//
//  Created by YoungjuneKwon on 2016. 6. 22..
//
//

import UIKit
import QuartzCore

class SummaryCont : UIViewController {
    var controller:BookController?

    @IBOutlet weak var bookTitle: UITextView!

    @IBOutlet weak var bookDescription: UITextView!

    @IBOutlet weak var bookDescriptionWrap: UIView!

    @IBOutlet weak var levelDotsArea: UIView!

    @IBOutlet weak var tagForProgress: UIImageView!
    
    @IBOutlet weak var tagForGenre: UIImageView!

    @IBOutlet weak var tagForGrade: UIImageView!
    
    @IBOutlet weak var downloadButton: UIButton!
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var globalBar: UIImageView!
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        if self.bookDescriptionWrap.layer.mask != nil {}
        else {
            let maskLayer:CALayer  = CALayer()
            maskLayer.bounds = CGRect(x: 0, y: 0,width: self.view.width,height: bookDescriptionWrap.height);
            maskLayer.anchorPoint = CGPoint.zero;
            maskLayer.contents = UIImage(named:"story_bg_sh_bottom_mask")?.cgImage
            
            bookDescriptionWrap.layer.mask = maskLayer
        }
    }
    
    func showOn(_ parent:UIView) {
        parent.addSubview(self.view)
        refresh()
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
    
    @IBAction func close(_ sender: AnyObject) {
        self.view.removeFromSuperview()
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
    }
    
    @IBAction func onDownload(_ sender: AnyObject) {
        ApplicationContext.sharedInstance.userViewModel.purchaseBook(controller!.book!)
        self.view.removeFromSuperview()
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
    }
    
    func refresh() {
        drawBookTitle(controller!.L!["title"].stringValue.replacingOccurrences(of: "_", with: "\n"))
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        let ats = [NSFontAttributeName: UIFont(name: "Helvetica Neue", size: 20.0)!, NSParagraphStyleAttributeName: paragraphStyle, NSForegroundColorAttributeName:UIColor.white]

        bookDescription.attributedText = NSAttributedString(string: controller!.L!["description"].stringValue, attributes: ats)
        
        let level:Int = controller!.model!["level"].intValue
        var idx = 1
        for v in levelDotsArea.subviews {
            let iv = v as! UIImageView
            iv.image = UIImage(named:idx <= level ? "story_icon_level_dot_on" : "story_icon_level_dot_off")
            idx += 1
        }

        self.perform(#selector(SummaryCont.scrollToTop), with: nil, afterDelay: 0.1)

        tagForProgress.image = UIImage(named:"story_icon_optional_kor_" + controller!.model!["status"].stringValue)
        guard controller!.model!["meta"].error == nil else { return }
        tagForGenre.image = UIImage(named:"story_icon_optional_kor_" + controller!.model!["meta"]["genre"].stringValue)
        tagForGrade.image = UIImage(named:"story_icon_class_" + controller!.model!["meta"]["age"].stringValue)
        
        backgroundImage.image = UIImage(data: (controller!.cachedBookResourceData(controller!.L!["cover"].stringValue)))!
    }

    func drawBookTitle(_ title:String) {
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.9
        paragraphStyle.alignment = .center
        let ats = [NSFontAttributeName: UIFont(name: "Helvetica Neue", size: 24.0)!, NSParagraphStyleAttributeName: paragraphStyle, NSForegroundColorAttributeName:UIColor.white]
        
        bookTitle.attributedText = NSAttributedString(string: title, attributes: ats)
    }
    
    func scrollToTop() {
        bookDescription.setContentOffset(CGPoint(x:0,y:0), animated: false)
        _ = downloadButton.circle().borderWith(UIColor.white, width: 1)
        downloadButton.imageView!.contentMode = .center
    }
}
