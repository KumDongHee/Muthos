//
//  TooltipCell.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 21..
//
//

import UIKit

class TooltipCell: UITableViewCell {

    @IBOutlet weak var contentsLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentsLabel.text = ""
    }
    
}
