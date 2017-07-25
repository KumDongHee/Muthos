//
//  SetMainCont.swift
//  Muthos
//
//  Created by 김성재 on 2016. 3. 3..
//
//

import UIKit
import RxSwift
import RxCocoa
import iCarousel
import SwiftAnimations
import SwiftyJSON

class SetMainCont: DefaultCont, iCarouselDataSource, iCarouselDelegate, RouletteDelegate, BillContDelegate, BookModeViewDelegate {
    
    @IBOutlet weak var priceImgView: UIImageView!
    @IBOutlet weak var bgImgView: UIImageView!
    @IBOutlet weak var carousel: iCarousel!
    @IBOutlet weak var setLabel: UILabel!
    @IBOutlet weak var bookTopBg: UIImageView!
    @IBOutlet weak var btnListen: UIView!
    @IBOutlet weak var btnTalk  : UIView!
    @IBOutlet weak var globalBar: UIView!
    @IBOutlet weak var bgShTop: UIImageView!
    @IBOutlet weak var bgListenShTop: UIImageView!
    @IBOutlet weak var bgListenShBottom: UIImageView!
    @IBOutlet weak var ordinaryButtonsWrap: UIView!
    @IBOutlet weak var bonusButtonsWrap: UIView!
    @IBOutlet var speakerThumbnail: UIImageView!
    @IBOutlet weak var micMute: UIImageView!
    @IBOutlet var roundButtons: [UIButton]!
    @IBOutlet weak var speakerThumbnailArea:UIView!
    @IBOutlet weak var swipeControl: UIControl!
    
    var controller:BookController = ApplicationContext.sharedInstance.sharedBookController
    var listen:ListenCont?
    var training:TrainingMainCont?
    var bill:BillCont?
    var modeView:BookModeView?
    
    deinit {
        bill = nil
    }
    
    var book:Book! {
        didSet {
            title = book.name
            self.controller.book = self.book
            listen = self.controller.getListenViewController()
        }
    }
    
    func initButtonStyle() {
        for b:UIButton in roundButtons {
            _ = b.circle()
            _ = b.borderWith(UIColor.white, width:1)
            b.imageView!.contentMode = .center
        }
        _ = speakerThumbnailArea.circle()
        speakerThumbnailArea.clipsToBounds = true

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(SetMainCont.respondToSwipeGesture(_:)))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(SetMainCont.respondToSwipeGesture(_:)))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left

        self.swipeControl.addGestureRecognizer(swipeRight)
        self.swipeControl.addGestureRecognizer(swipeLeft)
    }
    
    func respondToSwipeGesture(_ gesture: UIGestureRecognizer) {
        var result = false
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                print("Swiped right")
                result = selectIndex((controller.selectedIdx)! - 1)
            case UISwipeGestureRecognizerDirection.left:
                print("Swiped left")
                result = selectIndex((controller.selectedIdx)! + 1)
            default:
                break
            }
        }
        if result {
            carousel.scrollToItem(at: controller.selectedIdx!, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = true
        
        /* 훈련 전용 책인 경우에는 아예 훈련 첫화면만 표시하고 끝냄 */
        if isTrainingBook() {
            training = (BookController.loadViewController("TrainingCommon", viewcontroller: "TrainingMainCont") as! TrainingMainCont)
            training!.controller = controller
            view.addSubview(training!.view)
        }
        else {
            carousel.delegate = self
            carousel.dataSource = self
            carousel.type = .linear
            carousel.isPagingEnabled = false
            carousel.stopAtItemBoundary = true
            carousel.scrollSpeed = 1
            carousel.bounceDistance = 0.5
            
            view.addSubview((listen?.view)!)
            self.hideListen()
        }
    }

    func isTrainingBook() -> Bool {
        return self.controller.model!["category"].string!.hasPrefix("training")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setLabel.text = book.sets[0].title
        
        carousel.scrollToItem(at: 1, animated: false)
        carousel.scrollToItem(at: 0, animated: false)
        
        modeView = BookModeView.loadFromNib()
        
        if let modeView = modeView {
            if MainCont.isSmallScreen() {
                modeView.frame = CGRect(x:0,y:0,width:MainCont.scaledSize(145, r:0.8), height:MainCont.scaledSize(30, r:0.8))
            }
            
            modeView.delegate = self
            
            modeView.mode = controller.bookMode
            modeView.syncPosition()
            
            navigationItem.titleView = modeView
            
        }
        selectLastSet()
        self.performSelector(inBackground: #selector(SetMainCont.reloadBookContent), with: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        initButtonStyle()
    }
    
    func reloadBookContent() {
        guard let book = controller.book else { return }
        let data:Data = BookController.cachedBookResourceData(book._id!, resource:"/content.json", forceDownload:true)
        book.sets = []
        var bookJSON:JSON = JSON(data:data)
        if let arr = bookJSON["sets"].array {
            for s:JSON in arr {
                book.sets.append(BookSet(JSONString:s.rawString()!)!)
            }
        }
        self.performSelector(onMainThread: #selector(SetMainCont.reloadCarousel), with: nil, waitUntilDone: false)
    }
    
    func reloadCarousel() {
        guard let carousel = carousel else { return }
        carousel.reloadData()
    }
    
    func selectLastSet() {
        var lastSet:Int = 0
        if let user = ApplicationContext.sharedInstance.userViewModel.currentUserObject() {
            lastSet = user.getLastSetIndex(controller.book!._id!)
        }
        carousel!.scrollToItem(at: lastSet, animated: false)
        _ = selectIndex(lastSet)
    }
    
    // MARK: - Carousel
    func numberOfItems(in carousel: iCarousel) -> Int {
        if let b:Book = book {
            let bs:[BookSet] = b.sets
            return bs.count
        }
        return 0
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        let cardview = BookSetView.loadFromNib()
        guard book.sets.count > index else { return cardview}
        let bookset = book.sets[index]
        
        cardview.bookset = bookset
        if let setIndex = bookset.index {
            cardview.grade = ApplicationContext.currentUser.gradeForSetWithPath(
                book._id!, setIndex: String(setIndex), bookMode: controller.bookMode)
        }
        cardview.spaceFromCenter = carousel.offsetForItem(at: index)
        
        if index == 0 {
            cardview.isFirst = true
        }
        
        if index == book.sets.count - 1 {
            cardview.isLast = true
        }
        
        return cardview
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        _ = selectIndex(index)
    }
    
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
        _ = selectIndex(carousel.currentItemIndex)
    }
    
    func carouselDidScroll(_ carousel: iCarousel) {
        for i in 0..<carousel.numberOfItems {
            if let item = carousel.itemView(at: i) as? BookSetView {
                item.spaceFromCenter = carousel.offsetForItem(at: i)
            }
        }
    }
    
    func selectIndex(_ index:Int) -> Bool {
        guard index >= 0 && index < book.sets.count else { return false }
        controller.selectedIdx = index
        refresh()
        return true
    }

    let ALPHA_FOR_DISABLED:CGFloat = 0.4
    
    func setEnableListen(_ flag:Bool) {
        btnListen!.isUserInteractionEnabled = flag
        (btnListen! as! UIControl).isEnabled = flag
        _ = btnListen!.borderWith(flag ? UIColor.white : UIColor(white:1, alpha:ALPHA_FOR_DISABLED), width: 1)
    }

    func setEnableTalk(_ flag:Bool) {
        btnTalk!.isUserInteractionEnabled = flag
        (btnTalk! as! UIControl).isEnabled = flag
        _ = btnTalk!.borderWith(flag ? UIColor.white : UIColor(white:1, alpha:ALPHA_FOR_DISABLED), width: 1)
    }
    
    func refresh() {
        let bookset = book.sets[(controller.selectedIdx)!]
        let setObj:JSON = controller.model!["sets"][(controller.selectedIdx)!]
        
        /* 타이틀과 배경 관련 처리 */
        setLabel.text = bookset.title
        
        if let img = bookset.coverImage {
            if img.hasPrefix("/") {
                let image:UIImage = UIImage(data: (controller.cachedBookResourceData(img)))!
                bgImgView.image = image
            }
            else {
                bgImgView.image = UIImage(named: img)
            }
        }
        
        /* 하단 버튼 세트 관련 처리 */
        ordinaryButtonsWrap.isHidden = false
        bonusButtonsWrap.isHidden = true
        
        let setIndex:String = setObj["index"].stringValue
        let uv:UserViewModel = ApplicationContext.sharedInstance.userViewModel
        let hasCompleted = uv.hasCompletedPrioirSet(book._id!, setIndex: setIndex)

        print(book._id! + ", " + setIndex + "," + String(hasCompleted))
        
        setEnableTalk(false)
        setEnableListen(hasCompleted)

        if "roulette" == controller.model!["sets"][(controller.selectedIdx)!]["type"].stringValue {
            ordinaryButtonsWrap.isHidden = true
            bonusButtonsWrap.isHidden = false

            let bonusButton = bonusButtonsWrap.subviews[0] as! UIButton

            if uv.hasCompletedBookMode(book._id!, setIndex: setIndex, bookMode:controller.bookMode) {
                bonusButton.isEnabled = false
            }
            else {
                bonusButton.isEnabled = hasCompleted
            }
            _ = bonusButton.borderWith(bonusButton.isEnabled ? UIColor.white : UIColor(white:1, alpha:ALPHA_FOR_DISABLED), width: 1)
            
        }
        else {
            /* 리쓴 사용 내역이 있는 경우에만 토크 활성화 */
            if uv.lastAccessForListen(book._id!, setIndex: setIndex) > 0 {
                setEnableTalk(true)
            }
        }

        /* 화자 이미지 처리 */
        speakerThumbnail.isHidden = true
        if setObj["speakerImage"].error == nil {
            speakerThumbnail.image = UIImage(data:controller.cachedBookResourceData(setObj["speakerImage"].stringValue))
            speakerThumbnail.isHidden = false
        }
        
        let price = setObj["price"].error == nil ? setObj["price"].intValue : 100
        priceImgView.image = UIImage(named: "book_icon_"+(price == 0 ? "free" : String(price)))
    }
    
    // MARK: - event
    override func touchLeftButton() {
        super.touchLeftButton()
        if controller.isRouletteShown() {
            self.hideRoulette()
        }
        else if isTrainingBook() || (listen?.view)!.isHidden {
            ApplicationContext.playEffect(code: .bookClose)
            self.navigationController!.popViewController(animated: false)
        } else {
            self.hideListen()
        }
    }
    
    @IBAction func listen(_ sender: AnyObject) {
        let setIndex:String = (controller.model!["sets"][(controller.selectedIdx!)]["index"].stringValue)
        if ApplicationContext.sharedInstance.userViewModel.hasSet(book._id!, setIndex:setIndex) {
            self.showListen()
        } else {
            let set:JSON = controller.model!["sets"][controller.selectedIdx!]
            let price:Int = (set["price"].error == nil) ? set["price"].intValue : 100
            let coin:Int = ApplicationContext.currentUser.getCoin()
            
            guard coin >= price else {
                let alertController = UIAlertController(title: "알림", message:
                    "코인이 부족합니다.", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "확인", style: UIAlertActionStyle.default,handler: nil))
                present(alertController, animated: true, completion: nil)
                return
            }
            
            self.showBill()
        }
    }
    
    @IBAction func talk(_ sender: AnyObject) {
        self.showTalk()
    }
    
    @IBAction func onClickSpeaker(_ sender: AnyObject) {
        if micMute.isHidden {
            micMute.isHidden = false
        }
        else {
            micMute.isHidden = true
        }
        controller.muteSpeaker = !micMute.isHidden
    }
    
    func showTalk() {
        unowned let cont:SituationCont = controller.getTalkViewController() as! SituationCont
        cont.playMode = "talk"
        
        ApplicationContext.sharedInstance.userViewModel.updateLastSet(controller.book!._id!, index:controller.selectedIdx!)
        cont.reserveStart()
        self.navigationController?.pushViewController(cont, animated: true)
    }
    
    func combineCGRect(_ dest:CGRect, src:CGRect) -> CGRect {
        return CGRect(x: dest.origin.x + src.origin.x, y: dest.origin.y + src.origin.y,
                          width: dest.size.width + src.size.width, height: dest.size.height+src.size.height)
    }
    
    var carouselFrame:CGRect?
    
    func showListen() {
        unowned let cont:SituationCont = controller.getTalkViewController() as! SituationCont
        cont.playMode = "listen"
        ApplicationContext.sharedInstance.userViewModel.updateLastSet(controller.book!._id!, index:controller.selectedIdx!)
        cont.reserveStart()
        self.navigationController?.pushViewController(cont, animated: true)
    }
    
    func showListenBak() {
        bookTopBg.layer.opacity = 0
        bookTopBg?.isHidden = true
        btnTalk?.isHidden = true
        btnListen?.isHidden = true
        setLabel?.isHidden = true
        globalBar?.isHidden = true
        (listen?.view)!.isHidden = false
        (listen?.view)!.bounds = combineCGRect(bgImgView!.bounds, src: CGRect(x: 0,y: 0,width: 0,height: -64))
        (listen?.view)!.frame = combineCGRect(bgImgView!.frame, src:CGRect(x: 0,y: 0,width: 0,height: -64))
        
        (self.navigationItem.leftBarButtonItem?.customView! as! UIButton).setImage(UIImage(named: "gnb_top_icon_close"), for: UIControlState())
        
        listen?.perform(#selector(ListenCont.autoStart), with: nil, afterDelay: 0.5)

        bgListenShTop.isHidden = false
        bgListenShBottom.isHidden = false
        bgListenShTop.layer.opacity = 0
        bgListenShBottom.layer.opacity = 0

        self.carouselFrame = self.carousel?.frame
        
        animate {
            self.carousel?.frame = CGRect(x: (self.carousel?.frame.origin.x)!, y: (self.carousel?.frame.origin.y)!, width: (self.carousel?.frame.size.width)!, height: 1)
            self.bgListenShTop.layer.opacity = 1
            self.bgListenShBottom.layer.opacity = 1
            self.bgShTop.layer.opacity = 0
            
            self.bgImgView.frame = CGRect(x: self.bgImgView.frame.origin.x, y: self.bgImgView.frame.origin.y - 64, width: self.bgImgView.frame.size.width, height: self.bgImgView.frame.size.height)
            }.withDuration(0.2).withOptions(.curveEaseOut).completion({(finish) -> Void in
            })
    }
    
    func hideListen() {
        listen?.stopListening()
        (listen?.view)!.isHidden = true
        bookTopBg?.isHidden = false
        carousel?.isHidden = false
        btnTalk?.isHidden = false
        btnListen?.isHidden = false
        setLabel?.isHidden = false
        globalBar?.isHidden = false
        bookTopBg.layer.opacity = 1
        if let v = self.navigationItem.leftBarButtonItem?.customView {
            (v as! UIButton).setImage(UIImage(named: "gnb_top_icon_back"), for: UIControlState())
        }
        
        animate {
            self.bgListenShTop.layer.opacity = 0
            self.bgListenShBottom.layer.opacity = 0

            self.bgShTop.layer.opacity = 1

            if let frame = self.carouselFrame {
                self.carousel?.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: frame.size.height)
            }

            self.bgImgView.frame = CGRect(x: self.bgImgView.frame.origin.x, y: self.bgImgView.frame.origin.y + 64, width: self.bgImgView.frame.size.width, height: self.bgImgView.frame.size.height)
            }.withDuration(0.2).withOptions(.curveEaseOut).completion({(finish) -> Void in
                self.bgListenShTop.isHidden = true
                self.bgListenShBottom.isHidden = true
                
            })
    }

    func showBill() {
        let cont = mainboard.instantiateViewController(withIdentifier: "BillCont") as! BillCont
        cont.controller = self.controller
        cont.bgImage = getBackground()
        cont.delegate = self
        
        ApplicationContext.sharedInstance.userViewModel.updateLastSet(controller.book!._id!, index:controller.selectedIdx!)

        self.navigationController!.present(cont, animated: true, completion: { () -> Void in })
        
//        bill = nil
//        bill = BookController.loadViewController("Main", viewcontroller: "BillCont") as? BillCont
//        bill!.delegate = self
//        bill!.controller = self.controller
//        bill!.bgImage = getBackground()
//
//        var frame:CGRect = self.view.bounds
//        frame.origin.y = self.topLayoutGuide.length
//        frame.size.height -= self.topLayoutGuide.length
//        bill!.view.frame = frame
//        self.view.addSubview(bill!.view)
    }
    
    // MARK: - Roulette
    @IBAction func startRoulette(_ sender: AnyObject) {
        showRoulette()
    }
    
    func showRoulette() {
        bookTopBg.isHidden = true
        carousel.isHidden = true
        bonusButtonsWrap.isHidden = true
        controller.showRouletteOn(self)
        controller.roulette!.delegate = self
    }
    
    func hideRoulette() {
        controller.hideRoulette()
    }
    
    func rouletteClosed(_ roulette: RouletteCont) {
        bookTopBg.isHidden = false
        carousel.isHidden = false
        bonusButtonsWrap.isHidden = false
        roulette.delegate = nil
    }
    
    // MARK: - BillCont
    func billContDidClosed() {
        bill = nil
    }
    
    func billContDidPurchased() {
        bill = nil
        showListen()
    }
    
    // MARK: - BookModeView
    func bookModeDidChanged(view: BookModeView) {
        controller.bookMode = view.mode
        carousel.reloadData()
    }
}
