//
//  common.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 15..
//
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

let appDelegate = UIApplication.shared.delegate as! AppDelegate

func getBackground() -> UIImage? {
    let layer = UIApplication.shared.keyWindow?.layer
    let scale = UIScreen.main.scale
    UIGraphicsBeginImageContextWithOptions(layer!.frame.size, false, scale)
    layer!.render(in:UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image
}

//이메일 유효성 확인
func checkEmailValid(textField:UITextField, variable:Variable<Bool>) -> Observable<Bool> {
    var status = false
    
    return textField.rx.text.orEmpty
        .map { email -> Bool in
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
            
            let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            status = emailTest.evaluate(with: email)
            
            variable.value = status
            
            return status
    }
}

//비밀번호 유효성 확인
func checkPwdValid(textField:UITextField, variable:Variable<Bool>) -> Observable<Bool> {
    var status = false
    
    return textField.rx.text.orEmpty
        .map { pwd -> Bool in
            status = pwd.characters.count >= minimalPasswordLength
            
            variable.value = status

            return status
    }
}

//비밀번호 중복 확인
func checkPwdConfirmValid(textField1:UITextField, textField2:UITextField, variable:Variable<Bool>) -> Observable<Bool> {
    var status = false
    
    return Observable.combineLatest(textField1.rx.text.orEmpty, textField2.rx.text.orEmpty)
    { (pwd, confirmPwd) -> Bool in
        status =  false
    
        if pwd == confirmPwd {
            status = true
        }

        variable.value = status
        
        return status
    }
}
