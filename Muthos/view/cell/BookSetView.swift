//
//  BookSetCell.swift
//  Muthos
//
//  Created by Youngjune Kwon on 2016. 2. 2..
//  Copyright © 2016년 김성재. All rights reserved.
//

import UIKit

class BookSetView: UIView {
    let margin:CGFloat = 0.45
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ratingView: UIImageView!
    @IBOutlet weak var ratingWhiteView: UIImageView!
    @IBOutlet weak var bonusImgView: UIImageView!
    @IBOutlet weak var beforeLineView: UIView!
    @IBOutlet weak var afterLineView: UIView!
    
    var grade:Int = 0 {
        didSet {
            ratingView.backgroundColor = UIColor.clear
            ratingWhiteView.backgroundColor = UIColor.clear

            var imageurl:String
            var imageWhiteUrl:String
            
            if grade == 0 {
                ratingView.image = nil
                ratingWhiteView.image = nil
                return
            }
            
            switch (grade) {
            case 5:
                imageurl = "book_icon_crown"
            default:
                imageurl = "book_icon_star_" + String(grade - 1)
            }
            
            imageWhiteUrl = imageurl + "_white"
            
            ratingView.image = UIImage(named: imageurl)!
            ratingWhiteView.image = UIImage(named: imageWhiteUrl)!
        }
    }
    
    var bookset:BookSet! {
        didSet {
            if let rating = bookset.rating {
                self.grade = Int(rating)
                
                ratingView.isHidden = false
                ratingWhiteView.isHidden = false
            } else {
                ratingView.isHidden = true
                ratingWhiteView.isHidden = true
            }

            guard let isBonus = bookset.isBonus , isBonus else {
                //일반 세트
                bonusImgView.isHidden = true
                titleLabel.isHidden = false
                ratingView.isHidden = false
                ratingWhiteView.isHidden = false
                
                if let index = bookset.index {
                    titleLabel.text = String(format: "%d", index)
                }
                return
            }
            
            //보너스 세트인 경우
            bonusImgView.isHidden = false
            titleLabel.isHidden = true
            ratingView.isHidden = true
            ratingWhiteView.isHidden = true
        }
    }
    
    var spaceFromCenter:CGFloat! {
        didSet {
            let space = min(fabs(spaceFromCenter), 1)
            //0일때는 중심, 1일때 바깥
            
            if (spaceFromCenter > 0) {
                beforeLineView.backgroundColor = UIColor(white: 1, alpha: 0)
                
                if (!isLast) {
                    afterLineView.backgroundColor = UIColor(hexString: "d4d4d4")
                }
            } else {
                if (!isFirst) {
                    beforeLineView.backgroundColor = UIColor(hexString: "d4d4d4")
                }
                afterLineView.backgroundColor = UIColor(white: 1, alpha: 0)
            }
            
            if (fabs(spaceFromCenter) < 0.1) {
                beforeLineView.backgroundColor = UIColor(white: 1, alpha: 0)
                afterLineView.backgroundColor = UIColor(white: 1, alpha: 0)
            }

            let space_modified = max(min((space - margin)/(1-2*margin), CGFloat(1.0)), CGFloat(0.0))
            
            ratingWhiteView.alpha = 1-space_modified
            titleLabel.textColor = UIColor(white: 1-space_modified, alpha: 1)
            
            if bookset.isBonus == true {
                if space < 0.3 {
                    bonusImgView.image = UIImage(named:"book_icon_bonus_before_select")
                }
                else {
                    bonusImgView.image = UIImage(named:"book_icon_bonus_before")
                }
            }
        }
    }
    
    var isFirst:Bool = false {
        didSet {
            if (isFirst) {
                beforeLineView.backgroundColor = UIColor(white: 1, alpha: 0)
            }
        }
    }
    
    var isLast:Bool = false {
        didSet {
            if (isLast) {
                afterLineView.backgroundColor = UIColor(white: 1, alpha: 0)
            }
        }
    }
}
