//
//  TC_dictation.swift
//  muthos
//
//  Created by shining on 2017. 1. 17..
//
//

import Foundation

class TC_dictation : TC {
    var main:MainCont? = nil
    var book:Book? = nil
    
    func perform() {
        print("TC_dictation")
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
        var cont:SituationCont? = nil
        
        Async.series([
            {(nxt) -> Void in
                main.selectBook(book)

                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                    _ = nxt()
                }
            },
            {(nxt) -> Void in
                let sm:SetMainCont = main.navigationController!.topViewController as! SetMainCont
                sm.selectIndex(0)
                
                sm.modeView!.mode = .hard

                cont = controller.getTalkViewController() as! SituationCont
                guard let cont = cont else { _ = nxt(); return }
                
                cont.playMode = "talk"
                
                ApplicationContext.sharedInstance.userViewModel.updateLastSet(controller.book!._id!, index:controller.selectedIdx!)
                sm.navigationController?.pushViewController(cont, animated: true)

                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                    _ = nxt()
                }
            },
            {(nxt) -> Void in
                guard let cont = cont else { _ = nxt(); return }

//                cont.showDictationResult("hello world", desc:"hello sydny")
                nxt()
            }
            ], callback:{() -> Bool in return true})
    }
}
