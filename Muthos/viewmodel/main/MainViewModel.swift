//
// Created by 김성재 on 2016. 2. 15..
//

import Foundation
import RxSwift
import RxCocoa
import SwiftyJSON
import Alamofire

class MainViewModel {
    
    let url:String = ApiProvider.BASE_URL + "/res/books/list.json"
    
    let mainMode:BehaviorSubject<MainMode> = BehaviorSubject(value: .store)
    let categories:BehaviorSubject<[Category]> = BehaviorSubject(value: [])
    let books:BehaviorSubject<[Book]> = BehaviorSubject(value: [])
    var model:JSON?
    
    var disposeBag:DisposeBag!
    
    init() {
        disposeBag = DisposeBag()
        
        if let data:Data = try? Data(contentsOf: URL(string:self.url)!) {
            self.initWithJSON(JSON(data:data))
        }
    }
    
    func initWithJSON(_ json:JSON) {
        model = json
        var sampleCategory:[Category] = []
        
        for c:JSON in json["categories"].array! {
            let cate:Category = Category(JSONString:c.rawString()!)!
            for b:JSON in c["books"].array! {
                let bk:Book = Book(JSONString:b.rawString()!)!
                DispatchQueue.global().async {
                    let data:Data = BookController.cachedBookResourceData(bk._id!, resource:"/content.json")
                    var bookJSON:JSON = JSON(data:data)
                    if let arr = bookJSON["sets"].array {
                        for s:JSON in arr {
                            bk.sets.append(BookSet(JSONString:s.rawString()!)!)
                        }
                    }
                }
                cate.books.append(bk)
            }
            sampleCategory.append(cate)
        }
        
        mainMode.subscribe(onNext: { [unowned self] (mode) -> Void in
            if mode == MainMode.store {
                self.categories.onNext(sampleCategory)
            } else {
                self.books.onNext(ApplicationContext.currentUser.getMybooks(library:sampleCategory.flatMap({ (category) -> [Book] in return category.books })))
            }
        }).addDisposableTo(disposeBag)
    }
    
    deinit {
        self.categories.onCompleted()
        self.books.onCompleted()
        disposeBag = nil
    }
}

