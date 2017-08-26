//
//  FakeModelBuilder.swift
//  Example-Swift
//
//  Created by Robert Nash on 22/09/2015.
//  Copyright © 2015 Robert Nash. All rights reserved.
//

import UIKit
import Foundation

class MenuSection: CollapsableTableViewSectionModelProtocol  {
    
    var title: String
    var isVisible: Bool
    var items: [AnyObject]
    
    init() {
        title = ""
        isVisible = false
        items = []
    }
}

class ModelBuilder {
    
    class func buildMenu() -> [CollapsableTableViewSectionModelProtocol] {
        
        var collector = [CollapsableTableViewSectionModelProtocol]()
        
        let sampleTooltips1 = [
            Tooltip(JSON: ["contents": "북 아이콘을 길게 누르면 삭제를 할 수 있습니다.", "image": UIImage(named: "tooltip_img_01_store_01")!])!
        ]
        
        let sampleTooltips2 = [
            Tooltip(JSON: ["contents": "화면을 터치하면 음성 대사를 다시 들을 수 있습니다.", "image": UIImage(named: "tooltip_img_01_store_01")!])!,
            Tooltip(JSON: ["contents": "문장을 터치하면 문장 상세 화면을 볼 수 있습니다.", "image": UIImage(named: "tooltip_img_01_store_02")!])!,
            Tooltip(JSON: ["contents": "문장 상세 화면에서 MY NOTE 아이콘을 터치하면 문장이 MY NOTE에 담깁니다.", "image": UIImage(named: "tooltip_img_01_store_02")!])!
        ]
        
        let sampleTooltips3 = [
            Tooltip(JSON: ["contents": "MY NOTE는 MENU 항목에서 열 수 있습니다.", "image": UIImage(named: "tooltip_img_01_store_01")!])!
        ]

        
        var categories:[TooltipCategory] = []
        
        var category = TooltipCategory(JSON: ["title":"STORE"])!
        category.tooltips = sampleTooltips1
        categories.append(category)
        
        category = TooltipCategory(JSON: ["title":"TALK"])!
        category.tooltips = sampleTooltips2
        categories.append(category)

        category = TooltipCategory(JSON: ["title":"MY NOTE"])!
        category.tooltips = sampleTooltips3
        categories.append(category)

        for category in categories {
            let section = MenuSection()

            section.title = category.title!
            section.isVisible = false
            section.items = category.tooltips!
            
            collector.append(section)
        }
        
        return collector
    }
}
