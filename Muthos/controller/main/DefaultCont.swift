//
//  DefaultCont.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 21..
//
//

import UIKit
import RxSwift

class DefaultCont: UIViewController {

    let userViewModel = ApplicationContext.sharedInstance.userViewModel
    let mainboard = UIStoryboard(name: "Main", bundle: nil)
    var coinDisposable:Disposable?
    var disposeBag = DisposeBag()
    let cashButtonWrap:UIView = UIView(frame:CGRect(x:0,y:0,width:MainCont.scaledSize(30),height:MainCont.scaledSize(18.33)))
    let cashButton = UIButton(type: .custom)
    let coinWrap:UIView = UIView(frame:CGRect(x: 0,y: 0,width: MainCont.scaledSize(16),height: MainCont.scaledSize(30)))
    let rightButtonArea:UIView = UIView()
    let rightControl:UIControl = UIControl()
    let iconButton = UIButton(type: UIButtonType.custom)
    
    let MARGIN_TOP:CGFloat = MainCont.scaledSize(3)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navBarSetting()
        UIApplication.shared.statusBarStyle = .default
    }

    deinit {
        if let d:Disposable=coinDisposable {
            d.dispose()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        adjustToScaledSize()
    }
    
    override func viewDidLayoutSubviews() {
        adjustToScaledSize()
    }
    
    func adjustToScaledSize() {
//        navigationController?.navigationBar.frame = CGRect(x:0,y:0,width:MainCont.scaledSize(375),height:MainCont.scaledSize(64))
    }
    
    // MARK:- UI Setting
    func navBarSetting() {
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.barTintColor = UIColor.white
        navigationController?.navigationBar.isTranslucent = false
        
        let view:UIView = UIView(frame:CGRect(x: 0,y: 0,width: MainCont.scaledSize(150), height: MainCont.scaledSize(50)))
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: MainCont.scaledSize(3), width: MainCont.scaledSize(150), height: MainCont.scaledSize(50)))
        label.backgroundColor = UIColor.clear
        var fontsize : CGFloat = 17
        if UIDevice.current.userInterfaceIdiom == .pad {
            fontsize = 11
        }
        label.font = UIFont(name: "AppleGothic", size: MainCont.scaledSize(fontsize))
        label.textAlignment = .center;
        label.text = navigationItem.title;
        view.addSubview(label)

        self.navigationItem.titleView = view
        
        let leftButton = UIButton(type: UIButtonType.custom)
        
        if let nav = self.navigationController {
            if nav.viewControllers.count == 1 {
                leftButton.setImage(UIImage(named: "gnb_top_icon_menu"), for: UIControlState())
                leftButton.frame = CGRect(x: 0, y: 0, width: MainCont.scaledSize(21), height: MainCont.scaledSize(30))
            } else {
                leftButton.setImage(UIImage(named: "gnb_top_icon_back"), for: UIControlState())
                leftButton.frame = CGRect(x: 0, y: 0, width: MainCont.scaledSize(11), height: MainCont.scaledSize(30))
            }
        }
        
        
        leftButton.addTarget(self, action: #selector(DefaultCont.touchLeftButton), for: UIControlEvents.touchUpInside)

        let negativeSpacer:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target:nil, action:nil)
        negativeSpacer.width = MainCont.scaledSize(-3)
        self.navigationItem.leftBarButtonItems = [negativeSpacer,UIBarButtonItem(customView: leftButton)]
        
        iconButton.setImage(UIImage(named: "gnb_top_icon_coin"), for: UIControlState())
        iconButton.imageView!.contentMode = .scaleAspectFit
        iconButton.addTarget(self, action: #selector(DefaultCont.touchRightButton), for: UIControlEvents.touchUpInside)
        iconButton.frame = CGRect(x: MainCont.scaledSize(6), y: MARGIN_TOP, width: MainCont.scaledSize(16), height: MainCont.scaledSize(30))
        coinWrap.addSubview(iconButton)
        
        //cash 
        cashButton.addTarget(self, action: #selector(DefaultCont.touchRightButton), for: UIControlEvents.touchUpInside)
        cashButton.titleLabel!.font = UIFont(name: "AppleGothic", size: MainCont.scaledSize(15))!
        cashButton.setTitleColor(UIColor.black, for: .normal)
        cashButton.tintColor = UIColor.black

        cashButtonWrap.addSubview(cashButton)

        cashButtonWrap.frame = CGRect(x:0,y:0,width:cashButton.width, height:cashButton.height+3)
        cashButtonWrap.setNeedsDisplay()
        
        coinWrap.setNeedsDisplay()

        self.coinDisposable = userViewModel.currentCash
            .subscribe(onNext: {(cash) -> Void in
                self.updateCoinWithNumber(cash as NSNumber)
            })
        
        updateCoinWithNumber(userViewModel.currentUserObject()!.getCoin() as NSNumber)
        
        rightControl.addTarget(self, action: #selector(DefaultCont.touchRightButton), for: UIControlEvents.touchUpInside)

        coinWrap.setTop(MainCont.scaledSize(-2))
        rightControl.setTop(MainCont.scaledSize(-2))
        rightButtonArea.addSubview(coinWrap)
        rightButtonArea.addSubview(cashButtonWrap)
        rightButtonArea.addSubview(rightControl)
    }

    func updateCoinWithNumber(_ coin:NSNumber) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let title:String = formatter.string(from:(coin))!

        DispatchQueue.main.async {
            self.updateCoin(coin:title)
        }
        
    }
    
    let COIN_PADDING:CGFloat = 10
    
    func updateCoin(coin:String) {
        do {
            var coinsize = 15
            if UIDevice.current.userInterfaceIdiom == .pad {
                coinsize = 8
            }
            let str = try NSMutableAttributedString(data: coin.data(using: String.Encoding.unicode, allowLossyConversion: true)!, options: [ NSDocumentTypeDocumentAttribute: NSPlainTextDocumentType], documentAttributes: nil)
            str.addAttributes([NSFontAttributeName:UIFont(name: "AppleGothic", size: MainCont.scaledSize(CGFloat(coinsize)))!], range: NSMakeRange(0, str.length))
            str.addAttributes([NSKernAttributeName:-1.0], range: NSMakeRange(0, str.length))
            
            cashButton.setAttributedTitle(str, for: .normal)
        } catch {
        }
        
        cashButton.titleLabel!.sizeToFit()
        var coinmargin : CGFloat = 3
        if UIDevice.current.userInterfaceIdiom == .pad {
            coinmargin = 2
        }
        cashButton.frame = CGRect(x:0,y:MARGIN_TOP+MainCont.scaledSize(coinmargin),width:cashButton.titleLabel!.width, height:cashButton.titleLabel!.height)
        cashButtonWrap.frame = CGRect(x:0,y:0,width:cashButton.width, height:cashButton.height+MainCont.scaledSize(3))

        rightButtonArea.setWidth(coinWrap.width + cashButtonWrap.width + COIN_PADDING)
        rightButtonArea.setHeight(coinWrap.height)
        rightButtonArea.setTop(0)
        cashButtonWrap.setRight(rightButtonArea.width)
        cashButtonWrap.setCenterY(coinWrap.centerY)
        
        rightControl.frame = rightButtonArea.bounds

        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(customView:rightButtonArea)]
      
        cashButtonWrap.setNeedsLayout()
        coinWrap.setNeedsDisplay()
    }
    
    func touchLeftButton() {
        if let d:Disposable=coinDisposable {
            d.dispose()
        }
    }
    
    func touchRightButton() {
        let cont = mainboard.instantiateViewController(withIdentifier: "CoinCont") as! CoinCont
        cont.bgImage = getBackground()
        
        self.navigationController!.present(cont, animated: true, completion: { () -> Void in
        })
    }
    
}
