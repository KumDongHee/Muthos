//
//  UINavigationBar.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 22..
//  Copyright © 2016년 김성재. All rights reserved.
//

import UIKit

extension UINavigationBar {
    
    public func hideLine() {
        for parent in self.subviews {
            for childView in parent.subviews {
                if(childView is UIImageView) {
                    childView.isHidden = true
                }
            }
        }
    }
    
    public func showLine() {
        for parent in self.subviews {
            for childView in parent.subviews {
                if(childView is UIImageView) {
                    childView.isHidden = false
                }
            }
        }
    }
}
