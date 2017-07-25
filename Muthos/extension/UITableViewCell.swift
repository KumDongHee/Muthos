//
//  UITableViewCell.swift
//  Muthos
//
//  Created by 김성재 on 2016. 3. 7..
//
//

import Foundation
import UIKit

extension UITableViewCell {
    
    func addSeparatorLineToBottom(_ width:CGFloat){
        let lineFrame = CGRect(x: width, y: bounds.size.height, width: bounds.size.width-width, height: 0.5)
        let line = UIView(frame: lineFrame)
        line.backgroundColor = UIColor(hexString: "d4d4d4")
        addSubview(line)
    }
}
