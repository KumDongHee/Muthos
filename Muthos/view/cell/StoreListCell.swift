//
//  StoreDetailCell.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 28..
//  Copyright © 2016년 김성재. All rights reserved.
//

import UIKit
import HCSStarRatingView

protocol StoreListCellDelegate {
    func storeListCellDidTouchedThumbnail(_ cell:StoreListCell)
    func storeListCellDidTouchedButton(_ cell:StoreListCell)
}

class StoreListCell: UITableViewCell, DownloadContextDelegate {
    @IBOutlet weak var bookLabel: TopAlignedLabel!
    @IBOutlet weak var bookImage: UIImageView!
    @IBOutlet weak var eventButton: UIButton!
    @IBOutlet weak var ratingView: HCSStarRatingView!
    @IBOutlet weak var progressArea: UIView!
    @IBOutlet weak var progressText: UITextField!
    @IBOutlet weak var progressBar: UIView!
    
    var downloadContext:DownloadManager.DownloadContext?
    
    var delegate:StoreListCellDelegate?
    var status:Int = 0 {
        didSet {
            let statusString:[String] = ["get","down","down","open"];
            eventButton.setImage(UIImage(named: "store_btn_"+statusString[status]+"_default"), for: UIControlState())
            eventButton.setImage(UIImage(named: "store_btn_"+statusString[status]+"_pressed"), for: .selected)
            eventButton.setImage(UIImage(named: "store_btn_"+statusString[status]+"_pressed"), for: .highlighted)
            
            if status == 2 {
                eventButton.setImage(UIImage(named: "store_btn_"+statusString[status]+"_pressed"), for: UIControlState())
            }
        }
    }
    
    deinit {
        if let downloadContext = self.downloadContext {
            downloadContext.delegate = nil
        }
    }
    
    var book:Book! {
        didSet {
            layoutCell()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
   
    override func prepareForReuse() {
        super.prepareForReuse()
        bookLabel.text = ""
        bookImage.image = nil
    }
    
    func layoutCell() {
        bookLabel.text = book.name
        
        if let name = book.thumbimage {
            if name.hasPrefix("/") {
                bookImage.image = UIImage(data:BookController.cachedBookResourceData(book, resource: name))
            } else {
                bookImage.image = UIImage(named: name)
            }
        }

        var contains:Bool = false
        progressArea.isHidden = true
        
        if ApplicationContext.sharedInstance.downloadManager.contains(bookId: book._id!) {
            let downloadContext:DownloadManager.DownloadContext
                = ApplicationContext.sharedInstance.downloadManager.findContext(for: book)!
            downloadContext.delegate = self

            progressArea.isHidden = false
            progressText.text = ""
            progressBar.frame = progressArea.bounds
            progressBar.setHeight(0)

            contains = true
        }

        status = ApplicationContext.currentUser.hasBook(book)
            ? 3
            : (contains ? 2 : 0)

        //임시로
        let rating = arc4random() % 5
        ratingView.value = CGFloat(rating)
        ratingView.isUserInteractionEnabled = false
        
        bookLabel.font = UIFont.systemFont(ofSize: MainCont.scaledSize(17))
    }
    
    @IBAction func onClickThumbnail(_ sender: AnyObject) {
        if let d:StoreListCellDelegate=delegate {
            d.storeListCellDidTouchedThumbnail(self)
        }
    }
    
    @IBAction func onClickDownBtn(_ sender: AnyObject) {
        if let d:StoreListCellDelegate=delegate {
            d.storeListCellDidTouchedButton(self)
        }
    }
    
    func onProgressChanged(on context: DownloadManager.DownloadContext) {
        let progress:Int = Int(context.progress * 100)
        progressText.text = String(progress) + "%"
        progressBar.setHeight(progressArea.height * CGFloat(context.progress))
        progressBar.setBottom(progressArea.height)
    }
    
    func onDownloadCompleted(on context:DownloadManager.DownloadContext) {
        self.layoutCell()
    }
}
