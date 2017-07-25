//
//  SettingReportCont.swift
//  muthos
//
//  Created by wayfinder on 2017. 2. 18..
//
//

import UIKit
import RxSwift
import RxCocoa
import SVProgressHUD

enum ReportType {
    case error, suggestion
}

class SettingReportCont: DefaultCont {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var confirmButton: UIButton!
    
    var reportType:ReportType = .error
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        var str:String
        
        if self.reportType == .error {
            str = "오류신고"
        } else {
            str = "건의하기"
        }
        
        title = str
        titleLabel.text = str
        
        
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        //        toolBar.tintColor = UIColor(red: 92/255, green: 216/255, blue: 255/255, alpha: 1)
        toolBar.sizeToFit()
        
        // Adds the buttons
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneClick))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.setItems([spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        // Adds the toolbar to the view
        textView.inputAccessoryView = toolBar
        
        confirmButton.rx.tap
            .subscribe(onNext: {[unowned self] _ in
                ApiProvider.sendReportMessage(type:self.reportType == .error ? "오류" : "건의",
                                              message:self.textView.text, callback: {() -> Bool in
                    _ = self.navigationController?.popViewController(animated: true)
                    return true
                })
            }).addDisposableTo(disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchLeftButton() {
        super.touchLeftButton()
        _ = navigationController?.popViewController(animated: true)
    }
    
    func doneClick() {
        textView.resignFirstResponder()
    }
}
