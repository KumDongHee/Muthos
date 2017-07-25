//
//  QuitCont.swift
//  muthos
//
//  Created by wayfinder on 2017. 3. 1..
//
//

import UIKit

class QuitCont: DefaultCont {

    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var agreeButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "계정 탈퇴"
        bind()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func bind() {
        agreeButton.rx.tap
            .subscribe(onNext: {[unowned self] _ in
                self.checkButton.isSelected = !self.checkButton.isSelected
            }).addDisposableTo(disposeBag)
        
        confirmButton.rx.tap
            .subscribe(onNext: {[unowned self] _ in
                //TODO:- 확인 버튼 눌렀을 경우 처리
            }).addDisposableTo(disposeBag)
    }
    
    // MARK:- Actions
    override func touchLeftButton() {
        self.navigationController!.popViewController(animated: true)
    }
}
