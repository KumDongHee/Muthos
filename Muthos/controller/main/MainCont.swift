//
// Created by 김성재 on 2016. 2. 15..
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import SVProgressHUD
import ReachabilitySwift

protocol CellSelectDelegate {
    func selectBookCellFromStore(_ bookcell:BookCell)
}

class MainCont : DefaultCont, CellSelectDelegate, UINavigationControllerDelegate, BookCellDelegate {
    static let STANDARD_WIDTH:CGFloat = 375
    @IBOutlet weak var rightDotImgView: UIImageView!
    @IBOutlet weak var leftDotImgView: UIImageView!
    @IBOutlet weak var storeButton: UIButton!
    @IBOutlet weak var mybookButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    
    let defaultFont = UIFont(name: "AppleSDGothicNeo-Regular", size: 13.0)
    let selectedFont = UIFont(name: "AppleSDGothicNeo-Regular", size: 16.0)
    let defaultColor = UIColor.black
    let selectedColor = UIColor(red: 32, green: 154, blue: 0)
    
    var selectedBook: Book?
    var selectedCell: BookCell?
    
    static var SIZE_RATIO:CGFloat {
        get {
            return UIScreen.main.bounds.width / MainCont.STANDARD_WIDTH
        }
    }
    
    static var SCREEN_WIDTH:CGFloat {
        get {
            return UIScreen.main.bounds.width
        }
    }
    
    static var RETINA_SCALE:CGFloat {
        get {
            return UIScreen.main.scale
        }
    }
    static func scaledSize(_ v:CGFloat, r:CGFloat = MainCont.SIZE_RATIO) -> CGFloat {
        return v * r
    }
    
    static func scaledRect(_ rect:CGRect, r:CGFloat = MainCont.SIZE_RATIO) -> CGRect {
        return CGRect(x:rect.origin.x * r, y:rect.origin.y * r, width:rect.size.width * r, height:rect.size.height * r)
    }
    
    static func adjustScaledRect(_ view:UIView, r:CGFloat = MainCont.SIZE_RATIO) {
        view.frame = scaledRect(view.frame, r: r)
    }
    
    static func isSmallScreen() -> Bool {
        return UIScreen.main.bounds.width <= 320
    }
    
    let animationInterval = TimeInterval(0.2)
    
    let viewModel = MainViewModel()

    static var singleton:MainCont?
    
    static func sharedInstance() -> MainCont {
        if let s = singleton {
            return s
        } else {
            singleton = BookController.loadViewController("Main", viewcontroller: "MainCont") as? MainCont
            return singleton!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.delegate = self

        self.bind()
        checkReachability()
        collectionView.isHidden = false
        tableView.isHidden = true
    }
    
    func reloadData() {
        ApiProvider.asyncLoadUserModel({() -> Bool in
            DispatchQueue.main.async {
                self.selectMyBook()
            }
            return true
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let imageView = UIImageView(image: UIImage(named: "gnb_top_icon_logo"))
//        imageView.frame = CGRect(x:0,y:0,width:MainCont.scaledSize(40), height:MainCont.scaledSize(30))
        imageView.contentMode = .scaleAspectFit
        
        self.navigationController?.navigationBar.hideLine()
        self.navigationItem.titleView = imageView
    }
    
    func checkReachability() {
        guard let reachability:Reachability = Reachability() else { return }
        guard ApplicationContext.getValue(key: "NOTY-3G") != "false" else { return }

        if !reachability.isReachableViaWiFi {
            let alert = UIAlertController(title: "알림", message: "이동통신망 사용 시 데이터 요금이 청구될 수 있습니다.", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action: UIAlertAction!) in
            }))
            
            alert.addAction(UIAlertAction(title: "알림 설정 변경", style: .cancel, handler: { (action: UIAlertAction!) in
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let cont = storyboard.instantiateViewController(withIdentifier: "SettingCont")
                self.navigationController!.pushViewController(cont, animated: false)
            }))
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK:- UI Setting
    func bind() {
        let disposeBag = DisposeBag()
        
        self.storeButton.setTitleColor(defaultColor, for: UIControlState())
        self.storeButton.setTitleColor(selectedColor, for: .highlighted)
        self.storeButton.setTitleColor(selectedColor, for: .selected)
        
        self.mybookButton.setTitleColor(defaultColor, for: UIControlState())
        self.mybookButton.setTitleColor(selectedColor, for: .highlighted)
        self.mybookButton.setTitleColor(selectedColor, for: .selected)
        
        storeButton.rx.tap
            .subscribe(onNext: { self.selectStore() })
            .addDisposableTo(disposeBag)
        mybookButton.rx.tap
            .subscribe(onNext: { self.selectMyBook() })
            .addDisposableTo(disposeBag)
        viewModel.mainMode
            .subscribe(onNext: { [unowned self] (mode) -> Void in
                if mode == .store {
                    UIView.animate(withDuration: self.animationInterval,
                        animations: { () -> Void in
                            self.storeButton.titleLabel?.font = self.selectedFont
                            self.mybookButton.titleLabel?.font = self.defaultFont
                            self.storeButton.isSelected = true
                            self.mybookButton.isSelected = false
                            self.tableView.isHidden = false
                            self.collectionView.isHidden = true
                            self.leftDotImgView.isHidden = false
                            self.rightDotImgView.isHidden = true
                            self.tableView.reloadData()
                    })
                } else {
                    UIView.animate(withDuration: self.animationInterval,
                        animations: { () -> Void in
                            self.storeButton.titleLabel?.font = self.defaultFont
                            self.mybookButton.titleLabel?.font = self.selectedFont
                            self.storeButton.isSelected = false
                            self.mybookButton.isSelected = true
                            self.tableView.isHidden = true
                            self.collectionView.isHidden = false
                            self.leftDotImgView.isHidden = true
                            self.rightDotImgView.isHidden = false
                    })
                }
            }).addDisposableTo(disposeBag)
        
        
        //tableView
        ApplicationContext.sharedInstance.downloadManager.delegate = self
        tableViewSetting(disposeBag: disposeBag)
        
        //collection 
        collectionView.register(UINib(nibName: "BookCell", bundle: nil), forCellWithReuseIdentifier: "BookCell")
        
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        
        let pattern:UIImage = MainCont.scaleImage(UIImage(named: "store_bg_sh_resized")!, toSize: CGSize(width: MainCont.SCREEN_WIDTH, height: MainCont.scaledSize(192)/MainCont.RETINA_SCALE))
        collectionView.backgroundColor = UIColor(patternImage: pattern)
        
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumLineSpacing = MainCont.scaledSize(41)
        layout.sectionInset = UIEdgeInsets(top: MainCont.scaledSize(41), left: MainCont.scaledSize(15.5), bottom: 0, right: MainCont.scaledSize(15.5))
        layout.itemSize = CGSize(width: MainCont.scaledSize(104), height: MainCont.scaledSize(151))
        
        viewModel.books
            .bindTo(collectionView.rx.items(cellIdentifier:"BookCell", cellType: BookCell.self)) {row, element, cell in
                cell.book = element
                cell.delegate = self
            }.addDisposableTo(disposeBag)
        
        collectionView.rx.itemSelected
            .subscribe(onNext: { [unowned self] (indexPath) -> Void in
                if let cell = self.collectionView.cellForItem(at:indexPath) as? BookCell {
                    self.selectBookCellFromMyBook(cell)
                }
            }).addDisposableTo(disposeBag)

        self.disposeBag = disposeBag
    }
    
    func selectMyBook() {
        viewModel.mainMode.onNext(.myBook)
    }
    
    func selectStore() {
        viewModel.mainMode.onNext(.store)
    }
        
    static func scaleImage(_ image: UIImage, toSize newSize: CGSize) -> (UIImage) {
        let newRect = CGRect(x: 0,y: 0, width: newSize.width, height: newSize.height).integral
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context!.interpolationQuality = .high
        let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        context?.concatenate(flipVertical)
        context?.draw(image.cgImage!, in: newRect)
        let newImage = UIImage(cgImage: (context?.makeImage()!)!)
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // MARK: - Event
    func selectBookCellFromStore(_ bookcell: BookCell) {
        let controller:BookController = ApplicationContext.sharedInstance.sharedBookController
        controller.book = bookcell.book
        controller.showSummaryOn(self.view.superview!.superview!.superview!)
    }
    
    func selectBookCellFromMyBook(_ bookcell: BookCell) {
        if let book = bookcell.book {
            if book.sets.count == 0 {
                SVProgressHUD.showError(withStatus: "세트가 존재하지 않습니다.")
            } else {
                ApplicationContext.playEffect(code: .bookOpen)
                selectedBook = book
                selectedCell = bookcell
                
                BookController.displaySetMainOn(self, book:book)
//                self.performSegue(withIdentifier: "openSegue", sender: nil)
            }
        }
    }
    
    override func touchLeftButton() {
        super.touchLeftButton()
        self.mm_drawerController?.toggle(.left, animated: true, completion: { (_) -> Void in
//            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "openSegue" {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    func confirmRemoveMyBook(book:Book) {
        let bookName = book.name != nil ? book.name! + "\n" : ""
        
        let alert = UIAlertController(title: "알림", message: bookName + "마이북에서 삭제 하시겠습니까.", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        
        alert.addAction(UIAlertAction(title: "삭제", style: .default, handler: { (action: UIAlertAction!) in
            ApplicationContext.sharedInstance.userViewModel.hideFromMybook(book._id!)
            self.selectMyBook()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func longTouched(cell:BookCell) {
        confirmRemoveMyBook(book: cell.book)
    }
}
