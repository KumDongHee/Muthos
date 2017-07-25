//
//  SignupCont.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 10..
//
//

import UIKit
import SVProgressHUD
import RxSwift
import RxCocoa

let minimalPasswordLength = 4

class SignUpCont: UIViewController, UITextFieldDelegate {
    
    let emailFieldTag = 100
    let pwdFieldTag = 200
    let pwdConfirmFieldTag = 300
    
    let dispose:DisposeBag! = DisposeBag()
    
    let normalBorderColor = UIColor(hexString: "dddddd")
    let selectedBorderColor = UIColor(hexString: "f64d2b")
    let selectedBorderWidth:CGFloat = 3
    let normalBorderWidth:CGFloat = 1
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var pwdField: UITextField!
    @IBOutlet weak var pwdConfirmField: UITextField!
    
    @IBOutlet weak var emailView: BorderView!
    @IBOutlet weak var pwdView: BorderView!
    @IBOutlet weak var pwdConfirmView: BorderView!
    
    @IBOutlet weak var allButton: UIButton!
    @IBOutlet weak var firstButton: UIButton!
    @IBOutlet weak var secondButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "회원가입"
        
        let leftButton = UIButton(type: UIButtonType.custom)
        leftButton.setImage(UIImage(named: "gnb_top_icon_back"), for: UIControlState())
        leftButton.addTarget(self, action: #selector(SignUpCont.touchLeftButton), for: UIControlEvents.touchUpInside)
        leftButton.frame = CGRect(x: 0, y: 0, width: 20, height: 30)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)
        
        self.emailField.delegate = self
        self.pwdField.delegate = self
        self.pwdConfirmField.delegate = self
        
        self.emailField.tag = self.emailFieldTag
        self.pwdField.tag = self.pwdFieldTag
        self.pwdConfirmField.tag = self.pwdConfirmFieldTag
        
        // Do any additional setup after loading the view.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(SignUpCont.tapHandler))
        self.view.addGestureRecognizer(tapGesture)
        
        SVProgressHUD.setDefaultMaskType(.gradient)
        SVProgressHUD.setMinimumDismissTimeInterval(1.0)
        
        self.bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
    }
    
    func tapHandler() {
        self.view.endEditing(true)
    }
    
    func bind() {
        let emailValidStatus = Variable(false)
        let pwdValidStatus = Variable(false)
        let pwdConfirmStatus = Variable(false)
        let allValidStatus = Variable(false)
        
        let emailValid = checkEmailValid(textField: emailField, variable: emailValidStatus)
        let pwdValid = checkPwdValid(textField: pwdField, variable: pwdValidStatus)
        let pwdConfirmValid = checkPwdConfirmValid(textField1: pwdField, textField2: pwdConfirmField, variable: pwdConfirmStatus)
    
        Observable.combineLatest(emailValid, pwdValid, pwdConfirmValid) { $0 && $1 && $2 }
            .subscribe(onNext: { valid in
                allValidStatus.value = valid
            }).addDisposableTo(dispose)

        // check all button
        allButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                let checked = self.allButton.isSelected
                self.firstButton.isSelected = !checked
                self.secondButton.isSelected = !checked
                self.allButton.isSelected = !checked
                self.view.endEditing(true)
            }).addDisposableTo(dispose)

        // validation
        nextButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                if !emailValidStatus.value {
                    SVProgressHUD.showError(withStatus: "이메일을 확인해주세요.")
                    self.emailField.becomeFirstResponder()
                    return
                }
                
                if !pwdValidStatus.value {
                    SVProgressHUD.showError(withStatus: "비밀번호를 확인해주세요.")
                    self.pwdField.becomeFirstResponder()
                    return
                }

                if !pwdConfirmStatus.value {
                    SVProgressHUD.showError(withStatus: "비밀번호가 일치하지 않습니다.")
                    self.pwdField.becomeFirstResponder()
                    return
                }
                
            }).addDisposableTo(dispose)
        
        firstButton.rx.tap
            .subscribe(onNext: {[unowned self] in
                let checked = self.firstButton.isSelected
                self.view.endEditing(true)
                
                if !checked {
                    self.firstButton.isSelected = true
                } else {
                    self.firstButton.isSelected = false
                    self.allButton.isSelected = false
                }
            }).addDisposableTo(dispose)
        
        secondButton.rx.tap
            .subscribe(onNext: {[unowned self] in
                let checked = self.secondButton.isSelected
                self.view.endEditing(true)
                
                if !checked {
                    self.secondButton.isSelected = true
                } else {
                    self.secondButton.isSelected = false
                    self.allButton.isSelected = false
                }
            }).addDisposableTo(dispose)
        
        nextButton.rx.tap
            .filter { allValidStatus.value }
            .subscribe(onNext: {[unowned self] in
                print("all valid\n")
                
                // check확인 (selected는 signal이 없어서 따로)
                if (self.firstButton.isSelected && self.secondButton.isSelected) {
                    
                    let account = Account(JSON: [:])
                    account?.email = self.emailField.text
                    account?.password = self.pwdField.text
                    
                    let storyboard = UIStoryboard(name: "Account", bundle: nil)
                    let signupCont = storyboard.instantiateViewController(withIdentifier: "SignUpDetailCont") as! SignUpDetailCont
                    signupCont.account = account
                    self.navigationController?.pushViewController(signupCont, animated: true)
                } else {
                    //체크 없을 경우
                    SVProgressHUD.showError(withStatus: "약관 확인이 필요합니다.")
                }
            }).addDisposableTo(dispose)
        
        NotificationCenter.default.rx
            .notification(Notification.Name(rawValue: "UIKeyboardWillHideNotification"), object: nil)
            .subscribe(onNext: { [unowned self] _ in
                self.emailView.layer.borderColor = self.normalBorderColor.cgColor
                self.emailView.layer.borderWidth = self.normalBorderWidth
                self.pwdView.layer.borderColor = self.normalBorderColor.cgColor
                self.pwdView.layer.borderWidth = self.normalBorderWidth
                self.pwdConfirmView.layer.borderColor = self.normalBorderColor.cgColor
                self.pwdConfirmView.layer.borderWidth = self.normalBorderWidth
            }).addDisposableTo(dispose)
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {

        self.emailView.layer.borderColor = self.normalBorderColor.cgColor
        self.emailView.layer.borderWidth = self.normalBorderWidth
        self.pwdView.layer.borderColor = self.normalBorderColor.cgColor
        self.pwdView.layer.borderWidth = self.normalBorderWidth
        self.pwdConfirmView.layer.borderColor = self.normalBorderColor.cgColor
        self.pwdConfirmView.layer.borderWidth = self.normalBorderWidth
       
        switch textField.tag {
        case emailFieldTag:
            self.emailView.layer.borderColor = self.selectedBorderColor.cgColor
            self.emailView.layer.borderWidth = self.selectedBorderWidth
        case pwdFieldTag:
            self.pwdView.layer.borderColor = self.selectedBorderColor.cgColor
            self.pwdView.layer.borderWidth = self.selectedBorderWidth
        case pwdConfirmFieldTag:
            self.pwdConfirmView.layer.borderColor = self.selectedBorderColor.cgColor
            self.pwdConfirmView.layer.borderWidth = self.selectedBorderWidth
        default:
            break
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField.tag {
        case self.emailFieldTag:
            self.pwdField.becomeFirstResponder()
        case self.pwdFieldTag:
            self.pwdConfirmField.text = ""
            self.pwdConfirmField.becomeFirstResponder()
        default:
            self.view.endEditing(true)
        }
        return false
    }

    // MARK:- Actions
    func touchLeftButton() {
        self.navigationController!.popViewController(animated: true)
    }
}
