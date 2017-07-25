//
//  SettingCell.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 20..
//
//

import UIKit

class SettingCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nextImgView: UIImageView!
    @IBOutlet weak var userSwitch: UISwitch!
    @IBOutlet weak var subLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
   
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = ""
        subLabel.text = ""
    }
}
