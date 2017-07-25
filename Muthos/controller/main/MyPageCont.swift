//
//  MyPageCont.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 17..
//
//

import UIKit
import RxSwift
import RxCocoa

class MyPageCont:DefaultCont {
    
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var profileImgView: UIImageView!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameButton: UIButton!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var arcView: ArcView!
    @IBOutlet weak var expText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        self.title = "My Page"
        
        self.perform(#selector(MyPageCont.userDataSetting), with: nil, afterDelay:0.1)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.showLine()
    }
       
    func userDataSetting() {
        let user = ApplicationContext.currentUser
        
        profileImgView.layer.cornerRadius = profileImgView.frame.size.width/2.0
        profileImgView.layer.masksToBounds = true
        
        setProfileImage( UIImage(named: "mypage_portrait_default"))
     
        //profile image
        
        _ = profileButton.rx.tap
            .flatMapLatest { [weak self] _ in
                return UIImagePickerController.rx.createWithParent(self) { picker in
                    picker.sourceType = .photoLibrary
                    picker.allowsEditing = true
                }
                .flatMap { $0.rx.didFinishPickingMediaWithInfo }
                .take(1)
            }.map { info in
                return info[UIImagePickerControllerEditedImage] as? UIImage
            }.subscribe(onNext: { (image) in
                self.userViewModel.updateProfileImage(image)
                self.setProfileImage(image)
            }).addDisposableTo(disposeBag)
                
        
        self.nameLabel.text = user.name
        self.emailLabel.text = user.email!.hasPrefix("fb:") ? "" : user.email
            
        if let image = user.profileImage {
            self.setProfileImage(image)
        }
        
        //name change
        _ = nameButton.rx.tap
            .subscribe(onNext: { () in
            self.touchNameButton()
        }).addDisposableTo(disposeBag)
        
        let str = String(ApplicationContext.sharedInstance.userViewModel.getLevel())
        let exp = String(ApplicationContext.sharedInstance.userViewModel.getExp())
        let nextExp = String(ApplicationContext.sharedInstance.userViewModel.getNextExp())
        
        levelLabel!.text = "Lv. " + str
        expText.text = exp + " / " + nextExp
        
        arcView.lineCapStyle = .round
        arcView.rate = ApplicationContext.currentUser.getExpRate()
    }
    
    func setProfileImage(_ image:UIImage?) {
        profileImgView.image = image
        bgImageView.image = image
    }
    
    func cropToBounds(_ image: UIImage, width: CGFloat, height: CGFloat) -> UIImage {
        
        let contextImage: UIImage = UIImage(cgImage: image.cgImage!)
        
        let contextSize: CGSize = contextImage.size
        
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)
        
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        
        let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
    
    // MARK: - event 
    override func touchLeftButton() {
        super.touchLeftButton()
        self.navigationController!.popViewController(animated: true)
    }
    
    func touchNameButton() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let cont = storyboard.instantiateViewController(withIdentifier: "InputNameCont") as! InputNameCont
        cont.bgImage = self.bgImageView.image
        self.navigationController?.pushViewController(cont, animated: true)
    }
}
