//
//  FindPwdCont.swift
//  muthos
//
//  Created by wayfinder on 2017. 3. 1..
//
//

import UIKit
import PopupDialog

class FindPwdCont: DefaultCont {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet var confirmButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "비밀번호 찾기"
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
        view.addGestureRecognizer(gesture)
        
        coinWrap.isHidden = true
        cashButton.isHidden = true
        
        bind()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func bind() {
        confirmButton.rx.tap
            .subscribe(onNext: {[unowned self] _ in
                //TODO:- 확인 버튼 눌렀을 경우 처리
                //이메일 : self.emailField.text
                self.openDialog()
            }).addDisposableTo(disposeBag)
    }
    
    // MARK:- Actions
    override func touchLeftButton() {
        self.navigationController!.popViewController(animated: true)
    }
    
    func tapHandler() {
        view.endEditing(true)
    }
    
    func openDialog() {
        let overlayAppearance = PopupDialogOverlayView.appearance()
        
        overlayAppearance.color       = UIColor.black
        overlayAppearance.blurRadius  = 20
        overlayAppearance.blurEnabled = true
        overlayAppearance.liveBlur    = false
        overlayAppearance.opacity     = 0.5
        
        let dialogAppearance = PopupDialogDefaultView.appearance()
        dialogAppearance.roundCorner(5.0)
        
        // Create a custom view controller
        let cont = FindPwdConfirmCont(nibName: "FindPwdConfirmCont", bundle: nil)
        
        // Create the dialog
        let popup = PopupDialog(viewController: cont, buttonAlignment: .horizontal, transitionStyle: .zoomIn, gestureDismissal: true)
        
        // Present dialog
        present(popup, animated: true, completion: nil)
        
        cont.confirm = {[unowned self] () in
            popup.dismiss()
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
}
