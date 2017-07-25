//
//  SettingAgeCont.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 21..
//
//

import UIKit
import RxSwift
import RxCocoa
import DLRadioButton

class SettingAgeCont: DefaultCont {
	
    var selectedIndex:Int = 0
    
    @IBOutlet weak var allButton: DLRadioButton!
    @IBOutlet weak var twelveButton: DLRadioButton!
    @IBOutlet weak var fifteenButton: DLRadioButton!
    @IBOutlet weak var nineteenButton: DLRadioButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "키즈락"
    }
   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.showLine()
        
        //current language
        userViewModel.currentAge
            .subscribe(onNext: { [unowned self] (mode:AgeMode) -> Void in
                self.selectedIndex = mode.rawValue
                
                switch mode {
                case .all:
                    self.allButton.isSelected = true
                case .twelve:
                    self.twelveButton.isSelected = true
                case .fifteen:
                    self.fifteenButton.isSelected = true
                case .nineteen:
                    self.nineteenButton.isSelected = true
                }
            }).addDisposableTo(disposeBag)
    }
    
    // MARK:- UI Setting
    func radioSetting() {
        allButton.isMultipleSelectionEnabled = false
    }
    
    // MARK: - Actions
    @IBAction func touchRadioButton(_ button:UIButton) {
        self.selectedIndex = button.tag
    }
    
    @IBAction func touchConfirm(_ sender: AnyObject) {
        if let age = AgeMode(rawValue: self.selectedIndex) {
            userViewModel.updateAge(age)
        }
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func touchLeftButton() {
        super.touchLeftButton()
        _ = self.navigationController?.popViewController(animated: true)
    }
}
