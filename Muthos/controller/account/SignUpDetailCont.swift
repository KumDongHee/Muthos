//
//  SignUpDetailCont.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 15..
//
//

import UIKit
import SVProgressHUD
import RxSwift
import RxCocoa

class SignUpDetailCont: UIViewController {
    
    var account:Account?
    
    let dispose = DisposeBag()
    let datePicker = UIDatePicker()
    
    var keyboardToolbar:UIToolbar?
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var maleButton: UIButton!
    @IBOutlet weak var femaleButton: UIButton!
    @IBOutlet weak var birthButton: UIButton!
    @IBOutlet weak var birthField: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    
    var leftButton:UIButton = UIButton(type: UIButtonType.custom)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "회원가입"
        
        let leftButton = UIButton(type: UIButtonType.custom)
        leftButton.setImage(UIImage(named: "gnb_top_icon_back"), for: UIControlState())
        leftButton.addTarget(self, action: #selector(SignUpDetailCont.touchLeftButton), for: UIControlEvents.touchUpInside)
        leftButton.frame = CGRect(x: 0, y: 0, width: 20, height: 30)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)
        
        
        self.datePicker.datePickerMode = .date
        self.keyboardToolbar = UIToolbar(frame: CGRect(x: 0,y: 0,width: self.view.frame.width,height: 44))
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(SignUpDetailCont.doneHandler))
        let flexButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let fixButton = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
        fixButton.width = 10
        
        self.keyboardToolbar?.setItems([flexButton, doneButton, fixButton], animated: false)
        
        self.birthField.inputView = self.datePicker
        self.birthField.inputAccessoryView = self.keyboardToolbar
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(SignUpDetailCont.tapHandler))
        
        self.view.addGestureRecognizer(tapGesture)
        
        self.bind()
    }
    
    func tapHandler() {
        self.view.endEditing(true)
    }
    
    func doneHandler() {
        let date = self.datePicker.date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        self.birthField.text = formatter.string(from: date)
        self.account?.birthday = self.datePicker.date
        
        self.view.endEditing(true)
    }
    
    func bind() {
        maleButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                if !self.maleButton.isSelected {
                    self.account?.gender = "M"
                    self.maleButton.isSelected = true
                    self.femaleButton.isSelected = false
                }
            }).addDisposableTo(dispose);
        
        femaleButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                if !self.femaleButton.isSelected {
                    self.account?.gender = "F"
                    self.maleButton.isSelected = false
                    self.femaleButton.isSelected = true
                }
            }).addDisposableTo(dispose)
        
        birthButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                self.birthField.becomeFirstResponder()
            }).addDisposableTo(dispose)
        
        signupButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                //TODO: - 이름 글자수 체크
                if let nickname = self.nameField.text , nickname.characters.count >= 2 {
                    self.account?.nickname = nickname
                } else {
                    // 이름이 입력 안되었을 경우
                    SVProgressHUD.showError(withStatus: "이름을 입력하세요.")
                    return
                }
                
                //objecet->json
                if var accountJson = self.account?.toJSON() {
                    //생일은 따로 추가
                    accountJson["birthday"] = self.birthField.text
                    
                    SVProgressHUD.show(withStatus: "")
                    SVProgressHUD.setDefaultMaskType(.gradient)
                    ApiProvider.signUpWithEmail(accountJson as [String : AnyObject])
                        .subscribe(onNext: { (account) -> Void in
                            // 회원가입 성공
                            SVProgressHUD.showSuccess(withStatus: "")
                            appDelegate.goMain()
                        }, onError: { (error) -> Void in
                            // 회원가입 실패
                            //TODO: - ErrorType 대응
                            let error = ((error as Any) as! NSError)
                            SVProgressHUD.showError(withStatus: error.localizedDescription)
                            SVProgressHUD.setDefaultMaskType(.gradient)
                        }).addDisposableTo(self.dispose)
                }
            }).addDisposableTo(dispose)

/*
// 검증은 차후
        _ = self.nameField.rx_text.map({(email) -> Bool in
        if email.isEmpty {
        return false
        }
        //TODO: - 이름 검증
        return true
        }).bindTo(self.signupButton.rx_enabled)

*/
/*
//        당장은 핋요없어짐 / 차후 zip 참고용으로 남겨둠
        let keyboardSignal = NSNotificationCenter.defaultCenter().rx_notification("UIKeyboardWillShowNotification")
        _ = Observable.zip(birthButtonSignal, keyboardSignal) { (_,_) -> Void in }
            .subscribeNext({() -> Void in
                // 생일 입력시에만 반응
            }).addDisposableTo(self.dispose)
*/
    }
    
    // MARK:- Actions
    func touchLeftButton() {
        self.navigationController!.popViewController(animated: true)
    }
}
