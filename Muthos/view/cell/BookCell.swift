//
//  BookCell.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 23..
//  Copyright © 2016년 김성재. All rights reserved.
//

import UIKit

protocol BookCellDelegate {
    func longTouched(cell:BookCell)
}

class BookCell: UICollectionViewCell {

    @IBOutlet weak var bookImage: UIImageView!
    @IBOutlet weak var bookLabel: UILabel!
    @IBOutlet weak var bookmarkImgView: UIImageView!
    
    @IBOutlet weak var frontView: UIView!
    @IBOutlet weak var backView: UIView!
    
    var delegate:BookCellDelegate?
    
    var book:Book! {
        didSet {
            layoutCell()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(BookCell.longPressed))
        longPressRecognizer.minimumPressDuration = 1.5
        frontView.addGestureRecognizer(longPressRecognizer)
        // Initialization code
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.bookImage.image = nil
        self.bookLabel.text = ""
        self.bookmarkImgView.isHidden = true
    }
    
    func layoutCell() {
        bookLabel.text = book.name
        
        if MainCont.isSmallScreen() {
            bookLabel.font = UIFont(name: "AppleGothic", size: 10)
        }

        bookmarkImgView.isHidden = !book.bookmarked
        
        if let name = book.thumbimage {
            if name.hasPrefix("/") {
                bookImage.image = UIImage(data: BookController.cachedBookResourceData(book, resource: name))
            }else {
                bookImage.image = UIImage(named: name)
            }
        }
    }
    
    func longPressed(sender: UILongPressGestureRecognizer)
    {
        guard let delegate = self.delegate else { return }
        delegate.longTouched(cell: self)
    }
}
