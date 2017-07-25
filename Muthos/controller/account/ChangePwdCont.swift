//
//  ChangePwdCont.swift
//  muthos
//
//  Created by wayfinder on 2017. 3. 1..
//
//

import UIKit

class ChangePwdCont: DefaultCont {

    @IBOutlet weak var pwd1Field: UITextField!
    @IBOutlet weak var pwd2Field: UITextField!
    @IBOutlet weak var confirmButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
        view.addGestureRecognizer(gesture)
        
        title = "비밀번호 변경"
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
            }).addDisposableTo(disposeBag)
    }
    
    // MARK:- Actions
    override func touchLeftButton() {
        self.navigationController!.popViewController(animated: true)
    }
    
    func tapHandler() {
        view.endEditing(true)
    }
}
