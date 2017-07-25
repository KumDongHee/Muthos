//
//  FriendCont.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 18..
//
//

import UIKit
import RxSwift
import RxCocoa

class FriendCont: DefaultCont, UITableViewDelegate {

    @IBOutlet weak var friendTableView: UITableView!
    @IBOutlet weak var giftTableView: UITableView!
    @IBOutlet weak var friendButton: UIButton!
    @IBOutlet weak var giftButton: UIButton!
    
    let viewModel = FriendViewModel()
	
    let defaultFont = UIFont(name: "AppleSDGothicNeo-Regular", size: 13.0)
    let selectedFont = UIFont(name: "AppleSDGothicNeo-Regular", size: 16.0)
    let defaultColor = UIColor.black
    let selectedColor = UIColor(red: 32, green: 154, blue: 0)
    
    let animationInterval = TimeInterval(0.2)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Friends"

        topButtonSetting()
        friendTableViewSetting()
        giftTableViewSetting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.hideLine()
    }
    
    func topButtonSetting() {
        friendButton.rx.tap
            .subscribe(onNext:{ _ in self.viewModel.friendMode.onNext(.friendList)})
            .addDisposableTo(disposeBag)
        giftButton.rx.tap
            .subscribe(onNext:{ _ in self.viewModel.friendMode.onNext(.giftReceived)})
            .addDisposableTo(disposeBag)
        
        self.friendButton.setTitleColor(defaultColor, for: UIControlState())
        self.friendButton.setTitleColor(selectedColor, for: .highlighted)
        self.friendButton.setTitleColor(selectedColor, for: .selected)
        
        self.giftButton.setTitleColor(defaultColor, for: UIControlState())
        self.giftButton.setTitleColor(selectedColor, for: .highlighted)
        self.giftButton.setTitleColor(selectedColor, for: .selected)
        
        viewModel.friendMode.subscribe(onNext:{ [unowned self] (mode) -> Void in
            if mode == FriendMode.friendList {
                UIView.animate(withDuration: self.animationInterval,
                    animations: { () -> Void in
                        self.friendButton.titleLabel?.font = self.selectedFont
                        self.giftButton.titleLabel?.font = self.defaultFont
                        self.friendButton.isSelected = true
                        self.giftButton.isSelected = false
                        self.friendTableView.isHidden = false
                        self.giftTableView.isHidden = true
                })
            } else {
                UIView.animate(withDuration: self.animationInterval,
                    animations: { () -> Void in
                        self.friendButton.titleLabel?.font = self.defaultFont
                        self.giftButton.titleLabel?.font = self.selectedFont
                        self.friendButton.isSelected = false
                        self.giftButton.isSelected = true
                        self.friendTableView.isHidden = true
                        self.giftTableView.isHidden = false
                })
            }
        }).addDisposableTo(disposeBag)
    }

    func friendTableViewSetting() {
        friendTableView.register(UINib(nibName: "FriendCell", bundle: nil), forCellReuseIdentifier: "FriendCell")
        
        friendTableView.rowHeight = 66.5 
        friendTableView.separatorStyle = .none
        friendTableView.rx.setDelegate(self).addDisposableTo(disposeBag)
        
        userViewModel.currentFriends
            .bindTo(friendTableView.rx.items(cellIdentifier:"FriendCell", cellType: FriendCell.self)) { (row, element, cell) in
                cell.friend = element
                cell.selectionStyle = .none
                cell.addSeparatorLineToBottom(74.0)
                
                cell.giftButton.rx.tap
                    .subscribe(onNext: { [unowned self] _ in
                        let cont =  self.mainboard.instantiateViewController(withIdentifier: "GiftCont") as! GiftCont
                        cont.bgImage = getBackground()
                        cont.friend = element
                        
                        self.navigationController!.present(cont, animated: true, completion: { () -> Void in
                        })
                    }).addDisposableTo(self.disposeBag)
                
            }.addDisposableTo(disposeBag)
        
        friendTableView.rx.itemSelected.subscribe(onNext: { [unowned self](indexPath) -> Void in
            if let friends = try? self.userViewModel.currentFriends.value() {
                let friend = friends[indexPath.row]
                self.didSelectFriend(friend)
            }
            }).addDisposableTo(disposeBag)
    }
    
    func giftTableViewSetting() {
        giftTableView.register(UINib(nibName: "ReceiveGiftCell", bundle: nil), forCellReuseIdentifier: "ReceiveGiftCell")
        
        giftTableView.rowHeight = 66.5
        giftTableView.separatorStyle = .none
        giftTableView.rx.setDelegate(self).addDisposableTo(disposeBag)
        
        userViewModel.currentFriends
            .bindTo(giftTableView.rx.items(cellIdentifier: "ReceiveGiftCell", cellType: ReceiveGiftCell.self)) { (row, element, cell) in
                cell.user = element
                cell.selectionStyle = .none
                cell.addSeparatorLineToBottom(74.0)
                
                cell.rightButton.rx.tap
                    .subscribe(onNext: { [unowned self] _ in
                        
                    }).addDisposableTo(self.disposeBag)

            }.addDisposableTo(disposeBag)
        
        giftTableView.rx.itemSelected
            .subscribe(onNext: { [unowned self](indexPath) -> Void in
                if let users = try? self.userViewModel.currentFriends.value() {
                    let user = users[indexPath.row]
                    self.didSelectReceivedGift(user)
                }
            }).addDisposableTo(disposeBag)
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, editingStyleForRowAt editingStyleForRowAtIndexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.none
    }
    
    // MARK:- Action
    //cell 선택시
    func didSelectFriend(_ friend:User) {
       print(friend)
    }
  
    func didSelectReceivedGift(_ user:User) {
       print(user)
    }
    
    override func touchLeftButton() {
        super.touchLeftButton()
        self.navigationController!.popViewController(animated: true)
    }
}
