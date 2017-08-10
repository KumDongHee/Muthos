//
//  SettingAccountCont.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 21..
//
//

import UIKit
import RxSwift
import RxCocoa

class SettingAccountCont: DefaultCont, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profileImgView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var nameButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        title = "뮤토스 계정"
        
        userDataSetting()
        tableViewSetting()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.showLine()
    }
    
    func tableViewSetting() {
        self.automaticallyAdjustsScrollViewInsets = false
        
        tableView.register(UINib(nibName: "SettingCell", bundle: nil), forCellReuseIdentifier: "SettingCell")
        tableView.register(UINib(nibName: "SettingHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "SettingHeader")
        tableView.isScrollEnabled = false
        tableView.separatorColor = UIColor(hexString: "f1f1f1")
    }
    
    func userDataSetting() {
        profileImgView.layer.cornerRadius = profileImgView.frame.size.width/2.0
        profileImgView.layer.masksToBounds = true
        
        profileImgView.image = UIImage(named: "mypage_portrait_default")
        
        //profile image
        /*
        _ = profileButton.rx.tap
            .flatMapLatest { [weak self] _ in
                return UIImagePickerController.rx.createWithParent(self) { picker in
                    picker.sourceType = .PhotoLibrary
                    picker.allowsEditing = true
                    }
                    .flatMap { $0.rx_didFinishPickingMediaWithInfo }
                    .take(1)
            }.map { info in
                return info[UIImagePickerControllerEditedImage] as? UIImage
            }.subscribeNext{ [unowned self] (image) -> Void in
                self.userViewModel.updateProfileImage(image)
            }.addDisposableTo(disposeBag)
        */
        //user가 바뀔때마다 업데이트
        userViewModel.currentUser.subscribe(onNext: { [unowned self] (user) -> Void in
            self.nameLabel.text = user.name
            self.emailLabel.text = user.email
            
            if let image = user.profileImage {
                self.profileImgView.image = image
            }
        }).addDisposableTo(disposeBag)
        
        //name change
        nameButton.rx.tap
            .subscribe(onNext: { [unowned self]() -> Void in
                self.touchNameButton()
                }).addDisposableTo(disposeBag)
        
        logoutButton.rx.tap
            .subscribe(onNext: { [unowned self] (_) -> Void in
                ApiProvider.logout().subscribe(onNext: { (_) -> Void in
                    appDelegate.goLogin()
                }).addDisposableTo(self.disposeBag)
        }).addDisposableTo(disposeBag)
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingCell
        
        switch indexPath.row {
        case 0:
            cell.titleLabel.text = "비밀번호 변경"
        case 1:
            cell.titleLabel.text = "계정 탈퇴"
        default:
            cell.titleLabel.text = ""
        }
        
        cell.userSwitch.isHidden = true

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            let storyboard = UIStoryboard(name: "Account", bundle: nil)
            if let cont = storyboard.instantiateViewController(withIdentifier: "ChangePwdCont") as? ChangePwdCont {
                self.navigationController?.pushViewController(cont, animated: true)
            }
        case 1:
            let storyboard = UIStoryboard(name: "Account", bundle: nil)
            if let cont = storyboard.instantiateViewController(withIdentifier: "QuitCont") as? QuitCont {
                self.navigationController?.pushViewController(cont, animated: true)
            }
        default:
            break
        }        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SettingHeader") as! SettingHeader
        
        header.titleLabel.text = "계정 관리"
        
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
    
    // MARK:- Action
    override func touchLeftButton() {
        super.touchLeftButton()
        self.navigationController!.popViewController(animated: true)
    }

    func touchNameButton() {
        let storyboard = UIStoryboard(name: "Setting", bundle: nil)
        let cont = storyboard.instantiateViewController(withIdentifier: "SettingInputNameCont") as! SettingInputNameCont
        self.navigationController?.pushViewController(cont, animated: true)
    }
}
