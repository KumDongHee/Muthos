//
//  SettingTooltipDetailCont.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 21..
//
//

import Foundation
import UIKit
import iCarousel

class SettingTooltipDetailCont: DefaultCont, iCarouselDataSource, iCarouselDelegate {
    
    var section:CollapsableTableViewSectionModelProtocol?
    var row:Int?
    
    @IBOutlet weak var carousel: iCarousel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentsLabel: TopAlignedLabel!
    @IBOutlet weak var pageControl: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.title = "툴팁"
        
        settingCarousel()
        navBarSetting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.showLine()
        
        if let row = row , row < carousel.numberOfItems {
            carousel.scrollToItem(at: row, animated: false)
        }
    }

    func settingCarousel() {
        carousel.type = .linear
        carousel.delegate = self
        carousel.dataSource = self
        carousel.stopAtItemBoundary = true
        carousel.bounces = false
        carousel.clipsToBounds = true
        
        if let section = section {
            titleLabel.text = section.title
            
            if let item = section.items[0] as? Tooltip {
                contentsLabel.text = item.contents
            }
            
            pageControl.numberOfPages = section.items.count
            pageControl.currentPage = 0
        }
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        let view = UIImageView(frame: carousel.bounds)
        let overView = UIImageView(frame: carousel.bounds)
        overView.image = UIImage(named: "tooltip_bg_sh_bottom")
        
        view.addSubview(overView)
        
        if let item = section?.items[index] as? Tooltip {
            view.image = item.image
        }
        
        return view
    }
    
    func numberOfItems(in carousel: iCarousel) -> Int {
        if let count = section?.items.count {
            return count
        } else {
            return 0
        }
    }
    
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
        if let item = section?.items[carousel.currentItemIndex] as? Tooltip {
            contentsLabel.text = item.contents
            pageControl.currentPage = carousel.currentItemIndex
        }
    }
 
    // MARK: - Action
    override func touchLeftButton() {
        super.touchLeftButton()
        self.navigationController!.popViewController(animated: true)
    }

    @IBAction func touchPageControl(_ sender: UIPageControl) {
        print(sender.currentPage)
        carousel.scrollToItem(at: sender.currentPage, animated: true)
    }
}
