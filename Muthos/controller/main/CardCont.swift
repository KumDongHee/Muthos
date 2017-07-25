//
//  CardCont.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 29..
//  Copyright © 2016년 김성재. All rights reserved.
//

import UIKit
import iCarousel
import RxSwift

class CardCont: UIViewController, iCarouselDelegate, iCarouselDataSource {

    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var carousel: iCarousel!
    @IBOutlet weak var actionButton: UIButton!
   
    let cardSize:CGFloat = 1.15
    
    var bgImage:UIImage?
    var friend:User?
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let image = self.bgImage {
            self.bgImageView.image = image
        }
        
        self.carousel.delegate = self
        self.carousel.dataSource = self
        self.carousel.type = .linear
        
        actionButton.rx.tap
            .subscribe(onNext: { _ in
                self.dismiss(animated: true, completion: { () -> Void in
                })
        }).addDisposableTo(disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        
        if carousel.numberOfItems > 2 {
            carousel.scrollToItem(at: 1, animated: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
    }
    
    func numberOfItems(in carousel: iCarousel) -> Int {
        return 26
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        let s = String(describing: UnicodeScalar(97+index))
        
        if let image = UIImage(named: "mycard_card_" + s) {
            return UIImageView(image: image)
        } else {
            return UIImageView(image: UIImage(named: "mycard_card_a")!)
        }
    }
    
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        switch option {
        case .spacing:
            return 1.25
            
        case .visibleItems:
            return 3
            
        default:
            return value
        }
    }
    
    func carouselDidScroll(_ carousel: iCarousel) {
        let currentOffset = carousel.offsetForItem(at: carousel.currentItemIndex)
        let currentView = carousel.currentItemView
        
        let value = cardSize  - (cardSize - 1.0) * 2 * fabs(currentOffset)
        currentView?.transform = CGAffineTransform(scaleX: value, y: value)
    }
    
    @IBAction func goPrev(_ sender: AnyObject) {
        self.dismiss(animated: true) { () -> Void in
            
        }
    }
}
