//
//  PetCell.swift
//  Muthos
//
//  Created by shining on 2016. 9. 23..
//
//

import UIKit
import SwiftAnimations

protocol PetCellDelegate {
    func petcellDidSelected(_ cell:PetCell)
}

@IBDesignable class PetCell:UIView {
    var delegate:PetCellDelegate?
    
    static let selectedBackgroundColor:UIColor = UIColor(red: 0, green: 228, blue: 181)
    static let unselectedBackgroundColor:UIColor = UIColor(red: 234, green: 235, blue: 236)
    
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var progress: ArcView!
    @IBOutlet weak var face: UIImageView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var time: UITextField!
    
    var animating:Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    var hhmm:String = "" {
        didSet {
            time.text = hhmm
            time.sizeToFit()
            time.setRight(self.width+7)
            time.setWidth(time.width + 10)
            time.setHeight(time.height + 6)
            time.setTop(5)
            _ = time.circle()
            time.setNeedsLayout()
        }
    }
    var name:String = ""
    var selected:Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        time.translatesAutoresizingMaskIntoConstraints = true

        guard let number:String = MypetCont.PET_MAP[name] else { return }
        let imageName:String = "pet_btn_"+number+(selected ? "_02" : "_01")
        
        face.image = UIImage(named:imageName)
        background.backgroundColor = selected ? PetCell.selectedBackgroundColor : PetCell.unselectedBackgroundColor
        _ = background.circle()
        progress.borderColor = UIColor.clear
    }
    
    func initLayout() {
        progress.isHidden = true
        icon.isHidden = true
        time.isHidden = true
    }
    
    @IBAction func onClick(_ sender: AnyObject) {
        if (delegate != nil) {
            delegate?.petcellDidSelected(self)
        }
    }
    
    func startCoinAnimation() {
        animating = true
        icon.isHidden = false
        
        var prefix:String = ""
        let ab:[String] = MypetCont.findPetAbilityBy(name)
        if Int(ab[3])! > 0 {
            prefix = "mypet_motion_coin_0"
        }
        else if Int(ab[2])! > 0 {
            prefix = "mypet_motion_retry_0"
        }
        
        let FRAME:Int = 8
        var idx:Int = 0
        
        func doAnimate() {
            if idx == FRAME { finishAnimate(); return }

            let img:String = prefix + String(((idx % FRAME) + 1))

            print("doAnimate, "+img)

            animate {
                self.icon.image = UIImage(named:img)
                self.icon.layer.opacity = self.icon.layer.opacity - 0.1
                self.icon.setY(self.icon.y - 2)
                }.withDuration(0.01).completion { (finish) -> Void in
                    doAnimate()
                    idx += 1
            }
        }
        
        func finishAnimate() {
            animating = false
            self.icon.isHidden = true
            self.icon.setY(0)
            self.icon.layer.opacity = 1
        }
        
        doAnimate()
    }
}
