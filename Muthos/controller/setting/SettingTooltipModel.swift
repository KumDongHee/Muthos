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
            Tooltip(JSON: ["contents": "북 아이콘을 길게 누르면 위치 이동 및 삭제를 할 수 있습니다.", "image": UIImage(named: "tooltip_img_01_store_01")!])!,
            Tooltip(JSON: ["contents": "my book에서 삭제된 북 아이콘은 다시 받기 후에도 삭제 이전으로 돌아갈 수 없습니다.", "image": UIImage(named: "tooltip_img_01_store_02")!])!,
            Tooltip(JSON: ["contents": "북 아이콘을 길게 누르면 위치 이동 및 삭제를 할 수 있습니다.", "image": UIImage(named: "tooltip_img_01_store_01")!])!,
            Tooltip(JSON: ["contents": "my book에서 삭제된 북 아이콘은 다시 받기 후에도 삭제 이전으로 돌아갈 수 없습니다.", "image": UIImage(named: "tooltip_img_01_store_02")!])!
        ]
        
        let sampleTooltips2 = [
            Tooltip(JSON: ["contents": "북 아이콘을 길게 누르면 위치 이동 및 삭제를 할 수 있습니다.", "image": UIImage(named: "tooltip_img_01_store_01")!])!,
            Tooltip(JSON: ["contents": "my book에서 삭제된 북 아이콘은 다시 받기 후에도 삭제 이전으로 돌아갈 수 없습니다.", "image": UIImage(named: "tooltip_img_01_store_02")!])!
        ]
        
        var categories:[TooltipCategory] = []
        
        var category = TooltipCategory(JSON: ["title":"store"])!
        category.tooltips = sampleTooltips1
        categories.append(category)
        
        category = TooltipCategory(JSON: ["title":"my book"])!
        category.tooltips = sampleTooltips2
        categories.append(category)

        category = TooltipCategory(JSON: ["title":"contents"])!
        category.tooltips = sampleTooltips1
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
