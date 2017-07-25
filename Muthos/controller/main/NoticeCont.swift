//
//  NoticeCont.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 20..
//
//

import UIKit
import RxSwift
import RxCocoa

class NoticeCont: DefaultCont, UITableViewDelegate {

    let viewModel = AppViewModel.sharedInstance
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Notice"
        
        tableViewSetting()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.showLine()
    }
    
    // MARK:- UI Setting
    func tableViewSetting() {
        self.automaticallyAdjustsScrollViewInsets = false 
        
        tableView.register(UINib(nibName: "NoticeCell", bundle: nil), forCellReuseIdentifier: "NoticeCell")
        
        tableView.rx.setDelegate(self).addDisposableTo(disposeBag)
        tableView.rowHeight = 58
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(hexString: "e8e8e8")
        
        viewModel.notices
            .bindTo(tableView.rx.items(cellIdentifier:"NoticeCell", cellType: NoticeCell.self)) { (row, element, cell) in
                cell.notice = element
                cell.selectionStyle = .none
            }.addDisposableTo(disposeBag)
    }
   
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row % 2 == 0 {
            cell.backgroundColor = UIColor(hexString: "f3f3f3")
        } else {
            cell.backgroundColor = UIColor(hexString: "fcfcfc")
        }
    }
    
    // MARK: - event
    override func touchLeftButton() {
        super.touchLeftButton()
        self.navigationController!.popViewController(animated: true)
    }
}

//class ImageAttachment: NSTextAttachment {
//    var verticalOffset: CGFloat = 0.0
//    
//    // To vertically center the image, pass in the font descender as the vertical offset.
//    // We cannot get this info from the text container since it is sometimes nil when `attachmentBoundsForTextContainer`
//    // is called.
//    
//    convenience init(_ image: UIImage, verticalOffset: CGFloat = 0.0) {
//        self.init()
//        self.image = image
//        self.verticalOffset = verticalOffset
//    }
//    
//    override func attachmentBoundsForTextContainer(textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
//        
//        let height = lineFrag.size.height
//        var scale: CGFloat = 1.0;
//        let imageSize = image!.size
//        
//        if (height < imageSize.height) {
//            scale = height / imageSize.height
//        }
//        
//        return CGRect(x: 0, y: verticalOffset, width: imageSize.width * scale, height: imageSize.height * scale)
//    }
//}
