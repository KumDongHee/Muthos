//
//  InputNameCont.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 18..
//
//

import UIKit
import RxSwift

class SettingInputNameCont: DefaultCont {
    
    @IBOutlet weak var nameField: UITextField!
    
    var bgImage:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "뮤토스 계정"
        
        textFieldSetting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.showLine()
    }
    
    // MARK:- UI Setting
    func textFieldSetting() {
        nameField.becomeFirstResponder()
        
        let clearButton = nameField.value(forKey: "_clearButton")
        (clearButton as AnyObject).setImage(UIImage(named: "control_btn_close_default"), for: UIControlState())
        
        nameField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { [unowned self] () -> Void in
            ApplicationContext.sharedInstance.userViewModel.updateName(self.nameField.text)
        }).addDisposableTo(disposeBag)
    }
    
    // MARK: - event
    override func touchLeftButton() {
        super.touchLeftButton()
        self.navigationController!.popViewController(animated: true)
    }
}
