//
//  DownloadManager.swift
//  muthos
//
//  Created by shining on 2016. 11. 10..
//
//

import Foundation
import SwiftyJSON

protocol DownloadManagerDelegate {
    func didStartedDownload(for:DownloadManager.DownloadContext)
}

protocol DownloadContextDelegate {
    func onProgressChanged(on context:DownloadManager.DownloadContext)
    func onDownloadCompleted(on context:DownloadManager.DownloadContext)
}

class DownloadManager {
    var delegate:DownloadManagerDelegate?
    
    class DownloadContext {
        var delegate:DownloadContextDelegate?
        let book:Book
        var progress:Float = 0 {
            didSet {
                guard let delegate = self.delegate else { return }
                delegate.onProgressChanged(on: self)
            }
        }
        
        init(_ book:Book) {
            self.book = book
        }
    }
    
    var currentController:BookController?
    var queue:[DownloadContext] = []
    
    func enqueue(_ book:Book) {
        let context = DownloadContext(book)
        queue.append(context)
        if queue.count == 1 {
            processNext()
        }
    }
    
    func processNext() {
        guard queue.count > 0 else { return }
        let ctx = queue[0]
        let bc:BookController = BookController(book:ctx.book)
        bc.downloadResource(
            forSetIndexes:[1],
            onProgress:{(any:AnyObject) -> Bool in
            let pair:[Int] = any as! [Int]
            ctx.progress = Float(pair[0]) / Float(pair[1])
            print(ctx.progress)
            
            if pair[0] == pair[1] {
                self.queue.removeFirst()
                ApplicationContext.sharedInstance.userViewModel.purchaseBook(ctx.book)
                if let delegate = ctx.delegate {
                    delegate.onDownloadCompleted(on: ctx)
                }
                DispatchQueue.main.async { self.processNext() }
            }
            return true
        })
        
        if let delegate = self.delegate {
            delegate.didStartedDownload(for:ctx)
        }
    }
    
    func findContext(for book:Book) -> DownloadContext? {
        for c in queue {
            if c.book._id == book._id {
                return c
            }
        }
        return nil
    }
    
    func contains(bookId:String) -> Bool {
        for c in queue {
            if c.book._id == bookId {
                return true
            }
        }
        return false
    }
}
