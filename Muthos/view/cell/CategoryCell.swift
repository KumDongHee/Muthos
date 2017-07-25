//
//  CategoryCell.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 23..
//  Copyright © 2016년 김성재. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CategoryCell: UITableViewCell, UICollectionViewDelegate {

    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!

    // reactive하지는 않지만 이쪽이 더 간단하게 처리할 수 있을듯 
    var cellSelectDelegate:CellSelectDelegate?
    
    var disposeBag1:DisposeBag!
    var disposeBag2:DisposeBag!
    
    var category:Category! {
        didSet {
            let disposeBag = DisposeBag()
            
            titleLabel.text = category.name
            let books = Variable<[Book]>(category.books)
            
            books.asObservable()
                .bindTo(collectionView.rx.items(cellIdentifier:"BookCell", cellType: BookCell.self)) {row, element, cell in
                    cell.book = element
                    cell.bookmarkImgView.isHidden = true
            }.addDisposableTo(disposeBag)
            
            self.disposeBag1 = disposeBag
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        let disposeBag = DisposeBag()
        
        collectionView.register(UINib(nibName: "BookCell", bundle: nil), forCellWithReuseIdentifier: "BookCell")
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.rx.setDelegate(self).addDisposableTo(disposeBag)

        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumLineSpacing = MainCont.scaledSize(16)
        layout.sectionInset = UIEdgeInsets(top: 0, left: MainCont.scaledSize(15.5), bottom: 0, right: MainCont.scaledSize(15.5))
        layout.scrollDirection = .horizontal
        
        layout.itemSize = CGSize(width: MainCont.scaledSize(104), height: MainCont.scaledSize(151))
        
        collectionView.rx.itemSelected
            .subscribe(onNext: { [unowned self] (indexPath) -> Void in
//            let book = self.category.books[indexPath.row]
            if let delegate = self.cellSelectDelegate, let cell = self.collectionView.cellForItem(at: indexPath) as? BookCell {
                delegate.selectBookCellFromStore(cell)
            }
        }).addDisposableTo(disposeBag)
        
        titleLabel.font = UIFont(name: "AppleGothic", size: MainCont.scaledSize(15))

        self.disposeBag2 = disposeBag
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        
        //DisposeBag 제대로 활용하지 않으면 셀 반복 호출시 오류 발생 
        disposeBag1 = nil
    }
    
    deinit {
        disposeBag2 = nil
    }
}

 
