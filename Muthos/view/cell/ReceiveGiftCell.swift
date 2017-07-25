//
//  ReceiveGiftCell.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 28..
//  Copyright © 2016년 김성재. All rights reserved.
//

import UIKit

class ReceiveGiftCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var thumbImage: UIImageView!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var levelLabel: UILabel!
    
    var buttonTouched : (() -> User)?

    var user:User! {
        didSet {
            layoutCell()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.rightButton.setImage(UIImage(named: "friends_btn_present_default"), for: UIControlState())
        self.rightButton.setImage(UIImage(named: "friends_btn_present_default"), for: UIControlState.selected)
        self.rightButton.setImage(UIImage(named: "friends_btn_present_default"), for: UIControlState.highlighted)
        
        self.thumbImage.layer.cornerRadius = CGFloat(self.thumbImage.frame.width/2.0)
        self.thumbImage.layer.masksToBounds = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.titleLabel.text = ""
        self.thumbImage.image = nil
        self.levelLabel.text = ""
    }
    
    func layoutCell() {
        titleLabel.text = user.name
        levelLabel.text = "Lv.\(user.getLevel())"
        
        if let image = user.profileImage {
            thumbImage.image = image
        }
    }
}
