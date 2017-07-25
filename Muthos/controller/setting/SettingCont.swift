//
//  SettingCont.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 20..
//
//

import UIKit
import RxSwift
import RxCocoa
import ReachabilitySwift

class SettingCont: DefaultCont, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        self.title = "Setting"
        
        tableView.register(UINib(nibName: "SettingCell", bundle: nil), forCellReuseIdentifier: "SettingCell")
        tableView.register(UINib(nibName: "SettingHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "SettingHeader")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.showLine()
        self.navigationController?.navigationBar.isTranslucent = false
    }
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 2
        case 2:
            return 2
        case 3:
            return 3
        case 4:
            return 1
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingCell
        cell.selectionStyle = .none
        
        switch (indexPath as NSIndexPath).section {
        case 0:
            cell.titleLabel.text = "뮤토스 계정"
            cell.nextImgView.isHidden = false
            cell.userSwitch.isHidden = true
            
        case 1:
            switch (indexPath as NSIndexPath).row {
            case 0:
                cell.titleLabel.text = "언어선택"
                cell.titleLabel.alpha = 0.3
                
                //current language
                userViewModel.currentLanguage
                    .subscribe(onNext: { (mode:LanguageMode) -> Void in
                        cell.subLabel.text = mode.value
                    }).addDisposableTo(disposeBag)
                
            case 1:
                cell.titleLabel.text = "키즈락"
                cell.titleLabel.alpha = 0.3
            default:
                cell.titleLabel.text = ""
            }
            
            cell.nextImgView.isHidden = false
            cell.nextImgView.alpha = 0.3
            cell.userSwitch.isHidden = true
            
        case 2:
            switch (indexPath as NSIndexPath).row {
            case 0:
                cell.titleLabel.text = "이동통신망 사용알림"
                print(ApplicationContext.getValue(key:"NOTY-3G"))
                cell.userSwitch.isOn = ApplicationContext.getValue(key:"NOTY-3G") != "false"
                cell.userSwitch.rx.isOn
                    .subscribe({[unowned self] isOn in
                        ApplicationContext.putValue(key: "NOTY-3G", value: cell.userSwitch.isOn ? "true" : "false")
                    }).addDisposableTo(disposeBag)
            case 1:
                cell.titleLabel.text = "푸쉬알람 설정"
            default:
                cell.titleLabel.text = ""
            }
            
            cell.nextImgView.isHidden = true
            cell.userSwitch.isHidden = false
            
        case 3:
            switch (indexPath as NSIndexPath).row {
            case 0:
                cell.titleLabel.text = "툴팁"
            case 1:
                cell.titleLabel.text = "오류신고"
            case 2:
                cell.titleLabel.text = "건의하기"
            default:
                cell.titleLabel.text = ""
            }
            
            cell.nextImgView.isHidden = false
            cell.userSwitch.isHidden = true
        
        case 4:
            switch (indexPath as NSIndexPath).row {
            case 0:
                cell.titleLabel.text = "캐시 삭제"
            default:
                cell.titleLabel.text = ""
            }
            
            cell.nextImgView.isHidden = false
            cell.userSwitch.isHidden = true

//        case 4:
//            switch (indexPath as NSIndexPath).row {
//            case 0:
//                cell.titleLabel.text = "이용약관"
//            case 1:
//                cell.titleLabel.text = "프로그램 버전 정보"
//                if let text = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
//                    cell.subLabel.text = text
//                }
//            default:
//                cell.titleLabel.text = ""
//            }
//            
//            cell.nextImgView.isHidden = false
//            cell.userSwitch.isHidden = true

        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SettingHeader") as! SettingHeader
       
        switch section {
        case 0:
            header.titleLabel.text = "개인정보"
        case 1:
            header.titleLabel.text = "부가정보"
        case 2:
            header.titleLabel.text = "알림"
        case 3:
            header.titleLabel.text = "고객센터"
        case 4:
            header.titleLabel.text = "캐시삭제"
//        case 4:
//            header.titleLabel.text = "정보"
        default:
            header.titleLabel.text = ""
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Setting", bundle: nil)
        
        switch (indexPath as NSIndexPath).section {
        case 0:
            let cont = storyboard.instantiateViewController(withIdentifier: "SettingAccountCont")
            self.navigationController?.pushViewController(cont, animated: true)
            break
            
//        case 1:
//            if (indexPath as NSIndexPath).row == 0 {
//                let cont = storyboard.instantiateViewController(withIdentifier: "SettingLanguageCont")
//                self.navigationController?.pushViewController(cont, animated: true)
//            } else {
//                let cont = storyboard.instantiateViewController(withIdentifier: "SettingAgeCont")
//                self.navigationController?.pushViewController(cont, animated: true)
//            }
            
        case 3:
            switch (indexPath as NSIndexPath).row {
            case 0:
                let cont = storyboard.instantiateViewController(withIdentifier: "SettingTooltipCont")
                self.navigationController?.pushViewController(cont, animated: true)
                
            case 1:
                if let cont = storyboard.instantiateViewController(withIdentifier: "SettingReportCont") as? SettingReportCont {
                    cont.reportType = .error
                    self.navigationController?.pushViewController(cont, animated: true)
                }
                
            case 2:
                if let cont = storyboard.instantiateViewController(withIdentifier: "SettingReportCont") as? SettingReportCont {
                    cont.reportType = .suggestion
                    self.navigationController?.pushViewController(cont, animated: true)
                }

            default:
                break;
            }
            
        case 4:
            switch (indexPath as NSIndexPath).row {
            case 0:
                BookController.removeCache(self)
                break
            default:
                break
            }

//        case 4:
//            switch (indexPath as NSIndexPath).row {
//            case 1:
//                let cont = storyboard.instantiateViewController(withIdentifier: "SettingVersionCont")
//                self.navigationController?.pushViewController(cont, animated: true)
//            default:
//                break
//            }
        default:
            break
        }
    }
    
    // MARK: - Action
    override func touchLeftButton() {
        super.touchLeftButton()
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        }
    }
}
