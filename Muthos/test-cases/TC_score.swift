//
//  TC_score.swift
//  muthos
//
//  Created by shining on 2017. 1. 3..
//
//

import Foundation

class TC_score : TC {
    var main:MainCont? = nil
    var book:Book? = nil
    
    func perform() {
        print("TC_score")
        main = MainCont.sharedInstance()
        guard let main = main else {return}
        do {
            let cate = try main.viewModel.categories.value()[0]
            func waiting() {
                DispatchQueue.main.async {
                    if cate.books[0].sets.count == 0 {
                        waiting()
                        return
                    }
                    else {
                        self.book = cate.books[0]
                        self.doTest()
                    }
                }
            }
            waiting()
        } catch {
        }
    }
    
    func doTest() {
        guard let main = main else { return }
        guard let book = book else { return }
        let controller = ApplicationContext.sharedInstance.sharedBookController

        main.selectBook(book)
    
        let sm:SetMainCont = main.navigationController!.topViewController as! SetMainCont

        controller.showScoreOn(sm.view)
    }
}
