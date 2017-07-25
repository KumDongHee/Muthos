//
//  ListenCont.swift
//  Muthos
//
//  Created by Youngjune Kwon on 2016. 1. 30..
//  Copyright © 2016년 김성재. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import RxSwift
import RxCocoa
import QuartzCore

class ListenCont: UIViewController, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate {
    let HEIGHT_OF_PADDING_TOP:CGFloat = 12.5
    let HEIGHT_OF_PADDING_BOTTOM:CGFloat = 180
    let userViewModel = ApplicationContext.sharedInstance.userViewModel
    var disposeBag:DisposeBag! = DisposeBag()
    
    var controller:BookController?
    var dialogs:JSON?
    var speakers:JSON?
    var currentShown:Int = 0
    var btnPlay:UIButton?
    var playingStat:Int = 0
    var dummyCell:ListenCell?
    var profileImage:UIImage?
    var lastShown:Int = -1
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        var json:JSON = self.controller!.getSelectedListenModel()
        dialogs = json["dialogs"]
        speakers = json["speakers"]
        currentShown = 0
        
        btnPlay = UIButton(frame:CGRect(x: self.view.frame.size.width/2-35,y: self.view.frame.size.height-70-100,width: 70,height: 70))
        btnPlay?.addTarget(self, action: #selector(ListenCont.onClickPlay), for: UIControlEvents.touchUpInside)
        self.setButtonImage("control_btn_play")
        self.view.addSubview(btnPlay!)
        
        userViewModel.currentUser
            .subscribe(onNext: { [unowned self] (user) -> Void in
                if let image = user.profileImage {
                    self.profileImage = image
                    self.tableView.reloadData()
                }
            }).addDisposableTo(disposeBag)
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        if self.tableView.layer.mask != nil {}
        else {
            let maskLayer:CALayer  = CALayer()
            maskLayer.bounds = CGRect(x: 0, y: 0,width: self.view.width,height: self.view.height-64);
            maskLayer.anchorPoint = CGPoint.zero;
            maskLayer.contents = UIImage(named:"listen_bg_mask")?.cgImage
            
            tableView.layer.mask = maskLayer
        }
        self.scrollViewDidScroll(self.tableView)
    }
    
    func prepareDummyCell() -> ListenCell {
        if let cell:ListenCell = self.dummyCell {
            return cell
        }
        self.dummyCell = tableView.dequeueReusableCell(withIdentifier: "ListenCell") as? ListenCell
        return self.dummyCell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        _ = self.prepareDummyCell()
        if (indexPath as NSIndexPath).row == 0 {
            return HEIGHT_OF_PADDING_TOP
        }
        if (indexPath as NSIndexPath).row >= currentShown + 1{
            return HEIGHT_OF_PADDING_BOTTOM
        }
        let height:CGFloat = dummyCell!.determineHeightFor(dialogs![indexPath.row-1])
        return height
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentShown + 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListenCell") as! ListenCell

        if (indexPath as NSIndexPath).row == 0 || (indexPath as NSIndexPath).row >= currentShown + 1 {
            cell.isHidden = true
            return cell
        }
        
        let json:JSON = dialogs![indexPath.row-1]
        
        cell.frame = CGRect(x: cell.frame.origin.x, y: cell.frame.origin.y, width: tableView.frame.size.width, height: cell.frame.size.height)
        cell.setModel(json, speakers:speakers!)
        /* 화자가 "나" 인 경우에는 프로필 이미지를 내 이미지로 강제지정 */
        if let image = self.profileImage {
            cell.rightPic.image = image
        }
        cell.setPlaying(self.playingStat == 1 && (indexPath as NSIndexPath).row == currentShown)
        
        cell.isHidden = false
        if (indexPath as NSIndexPath).row == currentShown && lastShown < (indexPath as NSIndexPath).row - 1 {
            lastShown += 1
            cell.isHidden = true
            cell.playAnimation()
        }
        
        return cell
    }
    
    func setButtonImage(_ image:String) {
        btnPlay?.setImage(UIImage(named:image), for:UIControlState())
    }
    
    func onClickPlay() {
        if playingStat == 0 {
            currentShown = 0
            lastShown = -1
            self.setButtonImage("control_btn_pause")
            self.playListening()
            playingStat = 1
        }
        else if playingStat == 1 {
            self.setButtonImage("control_btn_play")
            self.pauseListening()
            playingStat = 2
        }
        else if playingStat == 2 {
            self.setButtonImage("control_btn_pause")
            self.playListening()
            playingStat = 1
        }
        self.tableView.reloadData()
    }
    
    func autoStart() {
        playingStat = 0
        onClickPlay()
    }
    
    func pauseListening()   { controller?.stopVoice(); playingStat = 2 }
    func playListening()    { playingStat = 1; self.engine() }
    func stopListening()    {
        controller?.stopVoice()
        self.setButtonImage("control_btn_play")
        self.playingStat = 0
    }
    
    func engine() {
        if currentShown >= (dialogs?.count)! {
            self.stopListening()
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
            return
        }
        controller?.playVoice((controller?.bookResourceURL((dialogs?[currentShown]["voice"].string!)!))!, callback: {()->Bool in
            self.performSelector(onMainThread: #selector(ListenCont.engine), with: nil, waitUntilDone: false)
            return true
        })
        currentShown += 1
        self.tableView.reloadData()
        self.perform(#selector(ListenCont.goBottom), with:nil, afterDelay:0.1)
    }
    
    func goBottom() {
        let indexPath = IndexPath(row: currentShown + 1, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView:UIScrollView)
    {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        scrollView.layer.mask!.position = CGPoint(x: 0, y: scrollView.contentOffset.y)
        CATransaction.commit()
    }
}
