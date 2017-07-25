//
//  NoticeCell.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 20..
//
//

import UIKit

class NoticeCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
   
    let dateFormatter = DateFormatter()
    
    var notice:Notice! {
        didSet {
            layoutCell()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        dateFormatter.dateFormat = "MMM d, yyyy"
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        dateLabel.text = ""
    }
    
    func layoutCell() {
        dateLabel.text = dateFormatter.string(from: notice.date! as Date)
        
        if notice.isNew != nil && notice.isNew! {
            //Get image and set it's size
            let image = UIImage(named: "notice_icon_new")!
            let newSize = CGSize(width: image.size.width+5, height: dateLabel.frame.height)
            
            //Resize image
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(x: 5, y: (dateLabel.frame.height-image.size.height), width: image.size.width, height: image.size.height))
            let imageResized = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            //Create attachment text with image
            let attachment = NSTextAttachment()
            attachment.image = imageResized
            let attachmentString = NSAttributedString(attachment: attachment)
            let myString = NSMutableAttributedString(string: notice.title!)
            myString.append(attachmentString)
            titleLabel.attributedText = myString
            
        } else {
            titleLabel.text = notice.title
        }
    }
}
