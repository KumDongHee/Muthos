//
//  InputNameCont.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 18..
//
//

import UIKit
import RxSwift
import RxCocoa

class InputNameCont: DefaultCont {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var bgImageView: UIImageView!
    
    var bgImage:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "My Page"
        
        textFieldSetting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let image = bgImage {
            self.bgImageView.image = image
        } else {
            self.bgImageView.image = UIImage(named: "mypage_portrait_default")
        }
        
        self.navigationController?.navigationBar.showLine()
    }

    func textFieldSetting() {
        nameField.becomeFirstResponder()
        
        // TODO: 오류 발생해서 임시 주석처리
//        let clearButton = nameField.value(forKey: "_clearButton")
//        (clearButton as AnyObject).setImage(UIImage(named: "control_btn_close_default"), for: UIControlState())
        
        nameField.rx.controlEvent(.editingDidEndOnExit)
            .subscribe(onNext: { [unowned self] () -> Void in
            ApplicationContext.sharedInstance.userViewModel.updateName(self.nameField.text)
        }).addDisposableTo(disposeBag)
    }
    
    // MARK: - event
    override func touchLeftButton() {
        super.touchLeftButton()
        self.navigationController!.popViewController(animated: true)
    }
}
