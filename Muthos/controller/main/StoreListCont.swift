//
//  StoreListCont.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 28..
//  Copyright © 2016년 김성재. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

// class StoreListCont: DefaultCont, UITableViewDelegate, StoreListCellDelegate, DownloadManagerDelegate {
extension MainCont : UITableViewDelegate, StoreListCellDelegate, DownloadManagerDelegate {
    
    // MARK:- UI Setting
    func tableViewSetting(disposeBag : DisposeBag) {
        self.tableView.register(UINib(nibName: "StoreListCell", bundle: nil), forCellReuseIdentifier: "StoreListCell")
        self.tableView.rx.setDelegate(self).addDisposableTo(disposeBag)
        self.tableView.showsHorizontalScrollIndicator = false
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = UIColor(hexString: "e8e8e8")
        self.tableView.rowHeight = 89
        
        if let categories = try? self.viewModel.categories.value() {
            if categories.count > 0 {
            let category = categories[0]
            let books = Variable<[Book]>(category.books)
            
            books.asObservable()
                .bindTo(tableView.rx.items(cellIdentifier: "StoreListCell", cellType: StoreListCell.self)) {row, element, cell in
                    cell.book = element
                    cell.selectionStyle = .none
                    cell.delegate = self
                }.addDisposableTo(disposeBag)
            
            tableView.rx.itemSelected
                .subscribe(onNext: { [unowned self] (indexPath) -> Void in
                    let book = category.books[indexPath.row]
                    self.selectBook(book)
                }).addDisposableTo(disposeBag)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row % 2 == 0 {
            cell.backgroundColor = UIColor(hexString: "f3f3f3")
        } else {
            cell.backgroundColor = UIColor(hexString: "fcfcfc")
        }
    }
    
    // MARK: - Event
    func selectBook(_ book: Book) {
    }
    
    func storeListCellDidTouchedThumbnail(_ cell:StoreListCell) {
        let controller:BookController = ApplicationContext.sharedInstance.sharedBookController
        controller.book = cell.book
        controller.showSummaryOn(self.view.superview!.superview!.superview!)
    }
    
    func storeListCellDidTouchedButton(_ cell:StoreListCell) {
        if cell.status == 0 {
            cell.status = 1
        }
        else if cell.status == 1 {
            ApplicationContext.sharedInstance.downloadManager.enqueue(cell.book)
            tableView.reloadData()
        }
        else if cell.status == 3 {
            BookController.displaySetMainOn(self, book: cell.book)
        }
    }
    
    // MARK: - DownloadManagerDelegate
    func didStartedDownload(for context:DownloadManager.DownloadContext) {
        tableView.reloadData()
    }
}
