//
//  BillCont.swift
//  Muthos
//
//  Created by shining on 2016. 9. 17..
//
//

import UIKit
import SwiftyJSON

protocol BillContDelegate {
    func billContDidClosed()
    func billContDidPurchased()
}

class BillCont:UIViewController {
    var delegate:BillContDelegate?
    var controller:BookController?
    var bgImage:UIImage?
    var price:Int = 0
    
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var btnOK: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var setLabel: UILabel!
    
    @IBOutlet weak var billArea: UIView!
    @IBOutlet weak var petFaceArea: UIView!
    
    @IBOutlet var textOrigins: [UITextField]!
    @IBOutlet weak var textDC: UITextField!
    
    @IBAction func onOK(_ sender: AnyObject) {
        doPurchase()
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
    }
    
    @IBAction func onCancel(_ sender: AnyObject) {
        hide()
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = UIRectEdge()
        
        if let image = bgImage {
            bgImageView.image = image
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        refresh()
    }
    
    func hide() {
        self.dismiss(animated: true) { () -> Void in
            if let d:BillContDelegate = self.delegate {
                d.billContDidClosed()
            }
        }
    }
    
    func doPurchase() {
        let email:String = ApplicationContext.currentUser.email!
        let bookId:String = controller!.book!._id!
        let setIndex:String = controller!.model!["sets"][controller!.selectedIdx!]["index"].stringValue
        
        ApiProvider.purchaseSet(email as AnyObject, bookId: bookId as AnyObject, setIndex: setIndex as AnyObject, callback: {(param:AnyObject) -> Bool in
            let json:JSON = JSON(param as! NSDictionary)
            if json["result"].string! == "0000" {
                ApiProvider.asyncLoadUserModel({() -> Bool in
                    DispatchQueue.main.async {
                        self.dismiss(animated: true) { () -> Void in
                            if let d:BillContDelegate = self.delegate {
                                d.billContDidPurchased()
                            }
                        }
                    }
                    return true
                })
            }
            else {
                let alertController = UIAlertController(title: "", message:
                    "세트 구매가 실패하였습니다.\n["+json["err"].stringValue+"]", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "확인", style: UIAlertActionStyle.default,handler: nil))

                self.dismiss(animated: true) { () -> Void in
                    if let d:BillContDelegate = self.delegate {
                        d.billContDidClosed()
                    }
                }
            }
            return true
        })
    }
    
    deinit {
        print("BillCont deinit")
    }
    
    func refresh() {
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent

        let set:JSON = controller!.model!["sets"][controller!.selectedIdx!]
        let setNo = controller!.model!["sets"][(controller?.selectedIdx)!]["index"].intValue
        
        titleLabel.text = set["title"].string!
        setLabel.text = String(format: "%02d", setNo)
        
        let originPrice:Int = (set["price"].error == nil) ? set["price"].intValue : 100
        var dcPrice:Int = originPrice
        var dcRate:Int = 0
        let user = ApplicationContext.currentUser
        let PET_MAP = ["3":"purchase_pet_3dc", "5":"purchase_pet_5dc", "7":"purchase_pet_7dc"]
        var selectedPets:[String] = []
        
        for ab:[String] in MypetCont.PET_ABILITIES {
            let name = ab[0]
            let dc:String = ab[1]
            guard dc != "0" else { continue }
            guard user.hasPet(name) else { continue }
            guard let img = PET_MAP[dc] else { continue }
            guard let dcInt = Int(dc) else {continue}
            
            dcRate = dcRate + dcInt
            selectedPets.append(img)
        }
        
        for tf in textOrigins { tf.text = String(originPrice) }
        dcPrice = Int(Float(originPrice) * (Float(100 - dcRate) / 100.0))
        textDC.text = String(dcPrice)

        for v in billArea.subviews { v.isHidden = true }
        billArea.subviews[dcRate == 0 ? 0 : 1].isHidden = false

        for v in petFaceArea.subviews { v.removeFromSuperview() }
        
        let PET_MARGIN:CGFloat = 20
        let PET_RECT = CGRect(x:0,y:0,width:65,height:85)
        let petsWidth = PET_RECT.size.width * CGFloat(selectedPets.count) + PET_MARGIN * CGFloat(max(0, selectedPets.count - 1))
        let offsetX = (petFaceArea.width - petsWidth) / 2
        var idx = 0
        for i in selectedPets {
            let img = UIImageView(image:UIImage(named:i))
            img.frame = PET_RECT
            img.setLeft((img.width + PET_MARGIN) * CGFloat(idx) + CGFloat(offsetX))
            petFaceArea.addSubview(img)
            idx += 1
        }
        
        self.price = dcPrice
    }
}
