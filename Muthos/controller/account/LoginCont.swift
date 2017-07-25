//
//  LoginCont.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 21..
//  Copyright © 2016년 김성재. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SVProgressHUD
import PopupDialog

class LoginCont: UIViewController, UITextFieldDelegate {

    let emailFieldTag = 100
    let pwdFieldTag = 200
    
    let dispose = DisposeBag()
    var loginEnabled:Observable<Bool>?
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var pwdField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.emailField.delegate = self
        self.pwdField.delegate = self
        
        self.emailField.tag = self.emailFieldTag
        self.pwdField.tag = self.pwdFieldTag
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(LoginCont.tapHandler))
        self.view.addGestureRecognizer(tapGesture)
        
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = true
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
    
    func bindViewModel() {
        let emailValidStatus = Variable(false)
        let pwdValidStatus = Variable(false)
		let allValidStatus = Variable(false)

        let emailValid = checkEmailValid(textField: emailField, variable: emailValidStatus)
        let pwdValid = checkPwdValid(textField: pwdField, variable: pwdValidStatus)
        
        Observable.combineLatest(emailValid, pwdValid) { $0 && $1 }
            .subscribe(onNext: { valid in
                allValidStatus.value = valid
            }).addDisposableTo(dispose)

        // validation
        loginButton.rx.tap
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
            }).addDisposableTo(dispose)
        
        loginButton.rx.tap
            .filter { allValidStatus.value }
            .subscribe(onNext: {[unowned self] _ in
                if let email = self.emailField.text, let password = self.pwdField.text {
                    let json = ["email": email, "password": password]
                    
                    ApiProvider.loginWithEmail(json as [String : AnyObject])
                        .subscribe(onNext: { (response, account) -> Void in
                            // 로그인 성공
                            SVProgressHUD.showSuccess(withStatus: "")
                            appDelegate.goMain()
                            
                        }, onError: { (error) -> Void in
                            // 로그인 실패
                            //TODO: - ErrorType 대응
                            SVProgressHUD.showError(withStatus: "로그인에 실패하였습니다.")
                        }).addDisposableTo(self.dispose)
                }
            }).addDisposableTo(dispose)
       
        signupButton.rx.tap
            .subscribe(onNext: {[unowned self] _ in
                let storyboard = UIStoryboard(name: "Account", bundle: nil)
                let signupCont = storyboard.instantiateViewController(withIdentifier: "SignUpCont") as! SignUpCont
                self.navigationController?.pushViewController(signupCont, animated: true)
            }).addDisposableTo(dispose)
    }
    
    func tapHandler() {
        self.view.endEditing(true)
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == self.emailFieldTag {
            self.pwdField.becomeFirstResponder()
        } else {
            self.view.endEditing(true)
            
            if self.loginButton.isEnabled {
                self.loginButton.sendActions(for: .touchUpInside)
            }
        }
        return false
    }
    
    @IBAction func findPassword(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Account", bundle: nil)
        let cont = storyboard.instantiateViewController(withIdentifier: "FindPwdCont")
        navigationController?.pushViewController(cont, animated: true)
    }
    
    @IBAction func findUserId(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Account", bundle: nil)
        let cont = storyboard.instantiateViewController(withIdentifier: "FindPwdCont")
        navigationController?.pushViewController(cont, animated: true)
    }
    
    @IBAction func onClickFBLogin(_ sender: AnyObject) {
        ApiProvider.facebookLogin(fromViewController: self)
    }
    
    @IBAction func onClickKakaoLogin(_ sender: AnyObject) {
        /*let session: KOSession = KOSession.shared();
        
        if session.isOpen() {
            session.close()
        }
        
        session.presentingViewController = self.navigationController
        session.open(completionHandler: { (error) -> Void in
            session.presentingViewController = nil
            
            if !session.isOpen() {
                switch ((error as! NSError).code) {
                case Int(KOErrorCancelled.rawValue):
                    break;
                default:
                    UIAlertView(title: "에러", message: error?.localizedDescription, delegate: nil, cancelButtonTitle: "확인").show()
                    break;
                }
            }
        }, authParams: nil, authTypes: [NSNumber(value: KOAuthType.talk.rawValue), NSNumber(value: KOAuthType.account.rawValue)])*/
    }
}
