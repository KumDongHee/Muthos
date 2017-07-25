//
//  FriendCell.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 28..
//  Copyright © 2016년 김성재. All rights reserved.
//

import UIKit

class FriendCell: UITableViewCell {

    @IBOutlet weak var thumbImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var giftButton: UIButton!
    @IBOutlet weak var levelLabel: UILabel!
    
    var friend:User! {
        didSet {
            layoutCell()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.thumbImage.layer.cornerRadius = CGFloat(self.thumbImage.frame.width/2.0)
        self.thumbImage.layer.masksToBounds = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.thumbImage.image = nil
        self.titleLabel.text = ""
        self.levelLabel.text = ""
    }
   
    func layoutCell() {
        titleLabel.text = friend.name
        levelLabel.text = "Lv.\(friend.getLevel())"
        
        if let image = friend.profileImage {
            thumbImage.image = image
        }
    }
}
