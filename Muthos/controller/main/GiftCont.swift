//
//  GiftCont.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 28..
//  Copyright © 2016년 김성재. All rights reserved.
//

import UIKit
import RxSwift

class GiftCont: UIViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var actionButton: UIButton!
    
    var bgImage:UIImage?
    var friend:User?
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        actionButton.rx.tap
            .subscribe(onNext: { _ in
                self.dismiss(animated: true, completion: { () -> Void in
            })
        }).addDisposableTo(disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        
        if let image = bgImage {
            bgImageView.image = image
        }

        if let friend = friend {
            nameLabel.text = friend.name
            profileImageView.layer.cornerRadius = self.profileImageView.frame.width/2.0
            profileImageView.layer.masksToBounds = true
            profileImageView.image = friend.profileImage
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
    }
    
    @IBAction func goPrev(_ sender: AnyObject) {
        self.dismiss(animated: true) { () -> Void in
            
        }
    }
}
