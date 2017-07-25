//
//  MenuCont.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 21..
//  Copyright © 2016년 김성재. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MenuCont: UIViewController, UIActionSheetDelegate {
    
//    @IBOutlet weak var profileImgView: UIImageView!
//    @IBOutlet weak var profileButton: UIButton!
//    @IBOutlet weak var petButton: UIButton!
    @IBOutlet weak var bookButton: UIButton!
//    @IBOutlet weak var friendButton: UIButton!
//    @IBOutlet weak var noticeButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    
    var disposeBag:DisposeBag! = DisposeBag()
    
    let userViewModel = ApplicationContext.sharedInstance.userViewModel

    static var singleton:MenuCont?
    
    static func sharedInstance() -> MenuCont {
        if let s = singleton {
            return s
        } else {
            singleton = BookController.loadViewController("Main", viewcontroller: "MenuCont") as? MenuCont
            return singleton!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.global().async {
            self.settingMenu()
        }
    }
    override func viewWillAppear(_ animated: Bool) {/*
        _ = self.profileImgView.circle()

        self.profileImgView.image = UIImage(named: "mypage_portrait_default")!

        if let image = ApplicationContext.currentUser.profileImage {
            self.profileImgView.image = image
        }*/
    }
    
    deinit {
        disposeBag = nil
    }
    
    func settingMenu() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
/*        profileButton.rx.tap
			.subscribe(onNext: { [unowned self] _ in
                if let nav = self.mm_drawerController?.centerViewController as? UINavigationController {
                    if !(nav.topViewController != nil && type(of:nav.viewControllers[nav.viewControllers.count-1]) == MyPageCont.self) {
                        let cont = storyboard.instantiateViewController(withIdentifier: "MyPageCont")
                        nav.pushViewController(cont, animated: false)
                    }
                }
                self.mm_drawerController?.closeDrawer(animated: true, completion: nil)
            }).addDisposableTo(disposeBag)
				
        petButton.rx.tap
			.subscribe(onNext: { [unowned self] _ in
                if let nav = self.mm_drawerController?.centerViewController as? UINavigationController {
                    if !(nav.topViewController != nil && type(of:nav.viewControllers[nav.viewControllers.count-1]) == MypetCont.self) {
                        let cont = BookController.loadViewController("Main", viewcontroller: "MypetCont") as! MypetCont
                        nav.pushViewController(cont, animated: true)
                    }
                }
                self.mm_drawerController?.closeDrawer(animated: true, completion: nil)
            }).addDisposableTo(disposeBag)
        
        friendButton.rx.tap
			.subscribe(onNext: { [unowned self] _ in
                if let nav = self.mm_drawerController?.centerViewController as? UINavigationController {
                    if !(nav.topViewController != nil && type(of:nav.viewControllers[nav.viewControllers.count-1]) == FriendCont.self) {
                        let cont = storyboard.instantiateViewController(withIdentifier: "FriendCont")
                        nav.pushViewController(cont, animated: true)
                    }
                }
                self.mm_drawerController?.closeDrawer(animated: true, completion: nil)
            }).addDisposableTo(disposeBag)
*/
        bookButton.rx.tap
			.subscribe(onNext: { [unowned self] _ in
                if let nav = self.mm_drawerController?.centerViewController as? UINavigationController {
                    if !(nav.topViewController != nil && type(of:nav.viewControllers[nav.viewControllers.count-1]) == MyNoteCont.self) {
                        let cont = storyboard.instantiateViewController(withIdentifier: "MyNoteCont")
                        nav.pushViewController(cont, animated: true)
                    }
                }
                self.mm_drawerController?.closeDrawer(animated: true, completion: nil)
            }).addDisposableTo(disposeBag)
        
/*        noticeButton.rx.tap
			.subscribe(onNext: { [unowned self] _ in
                if let nav = self.mm_drawerController?.centerViewController as? UINavigationController {
                    if !(nav.topViewController != nil && type(of:nav.viewControllers[nav.viewControllers.count-1]) == NoticeCont.self) {
                        let cont = storyboard.instantiateViewController(withIdentifier: "NoticeCont")
                        nav.pushViewController(cont, animated: false)
                    }
                }
                self.mm_drawerController?.closeDrawer(animated: true, completion: nil)
            }).addDisposableTo(disposeBag)
*/        
        settingButton.rx.tap
			.subscribe(onNext: { [unowned self] _ in
                if let nav = self.mm_drawerController?.centerViewController as? UINavigationController {
                    if !(nav.topViewController != nil && type(of:nav.viewControllers[nav.viewControllers.count-1]) == SettingCont.self) {
                        let cont = storyboard.instantiateViewController(withIdentifier: "SettingCont")
                        nav.pushViewController(cont, animated: false)
                    }
                }
                self.mm_drawerController?.closeDrawer(animated: true, completion: nil)
            }).addDisposableTo(disposeBag)
    }
}

