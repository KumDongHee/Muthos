//
//  CoinCont.swift
//  Muthos
//
//  Created by 김성재 on 2016. 2. 22..
//
//

import UIKit
import RxSwift
import RxCocoa
import SMIconLabel
import iCarousel
import StoreKit

class CoinCont: UIViewController, iCarouselDelegate, iCarouselDataSource, SKPaymentTransactionObserver, SKProductsRequestDelegate {

    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var coinLabel: SMIconLabel!
    @IBOutlet weak var carousel: iCarousel!
    
    @IBAction func purchaseProduct(sender: AnyObject) {
        actionButton.isEnabled = false
        inPurchase = true
        let payment = SKPayment(product: product!)
        SKPaymentQueue.default().add(payment)
    }
    
    let disposeBag:DisposeBag! = DisposeBag()
    let userViewModel = ApplicationContext.sharedInstance.userViewModel
    
    var bgImage:UIImage?
    
    var product:SKProduct?
    var productID = "muthos.coins.5000"
    
    var inPurchase = false;

    override func viewDidLoad() {
        super.viewDidLoad()
        
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
        
        actionButton.isEnabled = false
        
        getProductInfo()
        
        if let image = bgImage {
            bgImageView.image = image
        }
        
        /*actionButton.rx.tap
            .subscribe(onNext: { [unowned self] _ in
                self.dismiss(animated: true, completion: { [unowned self] () -> Void in
                    //실제 충전
                    self.callPurchase()
                    
                    //충전화면
                    do {
                        var currentCash = try self.userViewModel.currentCash.value()
                        
                        switch self.carousel.currentItemIndex {
                        case 0:
                            currentCash += 5000
                        case 1:
                            currentCash += 11000
                        case 2:
                            currentCash += 35000
                        case 3:
                            currentCash += 60000
                        case 4:
                            currentCash += 130000
                        default:
                            break
                        }
                        //self.userViewModel.updateCash(currentCash)
                        //ApiProvider.asyncSaveUserModel(ApplicationContext.currentUser)
                    } catch {}

                })
        }).addDisposableTo(disposeBag)*/
        
        //cash
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        ApplicationContext.sharedInstance.userViewModel.currentCash.subscribe(onNext: { [unowned self](cash) -> Void in
            self.coinLabel.sizeToFit()
            self.coinLabel.icon = UIImage(named: "coin_img_coin")
            self.coinLabel.iconPadding = 17
            self.coinLabel.text = formatter.string(from:(cash as NSNumber))

            //            self.coinLabel.iconPosition = .horizontal.left
        }).addDisposableTo(disposeBag)
        
        carousel.type = .linear
        carousel.bounces = false
        carousel.scrollToItemBoundary = true
        carousel.isPagingEnabled = true
    }
    
    /*func callPurchase() {
        actionButton.isEnabled = false
        let payment = SKPayment(product: product!)
        SKPaymentQueue.default().add(payment)
    }*/
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        
    //    SKPaymentQueue.default().add(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
        
        SKPaymentQueue.default().remove(self)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getProductInfo(){
        if SKPaymentQueue.canMakePayments() {
            // 애플에 상품 정보 요청, 요청이 완료되면 바로 아래 함수인 productsRequest함수가 자동 호출된다.
            let request = SKProductsRequest(productIdentifiers: NSSet(object: self.productID) as! Set<String>)
            request.delegate = self
            request.start()
        }else{
            return
        }
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response:SKProductsResponse){
        
        var products = response.products
        // 상품 정보가 정상적으로 수신되었을 경우 화면에 상품 정보 갱신 및 구매 버튼 활성화 처리한다.
        if products.count != 0 {
            product = products[0] as SKProduct
            if inPurchase != true {
                actionButton.isEnabled = true
            }
        }else{
        }
        
        let productList = response.invalidProductIdentifiers
        for productItem in productList{
            print("Product not found : \(productItem)")
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        for trans in queue.transactions {
            queue.finishTransaction(trans)
        }
        
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions as [SKPaymentTransaction]{
            switch transaction.transactionState {
            case SKPaymentTransactionState.purchased:
                // 구매가 정상적으로 완료될 경우 후처리 시작
                self.unlockFeature()
                //SKPaymentQueue.default().finishTransaction(transaction)
                queue.finishTransaction(transaction)
                break
            case SKPaymentTransactionState.failed:
                //SKPaymentQueue.default().finishTransaction(transaction)
                queue.finishTransaction(transaction)
                inPurchase = false;
                actionButton.isEnabled = true;
            default:
                break
            }
        }
    }
    
    func unlockFeature(){
        do {
            var currentCash = try self.userViewModel.currentCash.value()
            
            switch self.carousel.currentItemIndex {
            case 0:
                currentCash += 5000
            case 1:
                currentCash += 11000
            case 2:
                currentCash += 35000
            case 3:
                currentCash += 60000
            case 4:
                currentCash += 130000
            default:
                break
            }
            
            self.dismiss(animated: true, completion: {
                self.userViewModel.updateCash(currentCash)
                ApiProvider.asyncSaveUserModel(ApplicationContext.currentUser)
            })
            
        } catch {}
        
        return
    }
    
    //MARK: - iCarousel
    func numberOfItems(in carousel: iCarousel) -> Int {
        return 5
    }
    
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        switch option {
        case .spacing:
            return 2
            
        case .visibleItems:
            return 1
            
        default:
            return value
        }
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        let imageView = UIImageView(frame: carousel.bounds)
        imageView.contentMode = .center
        
        switch index {
        case 0:
            imageView.image = UIImage(named: "coin_img_5")
            self.productID = "muthos.coins.5000"
        case 1:
            imageView.image = UIImage(named: "coin_img_10")
            self.productID = "muthos.coins.11000"
        case 2:
            imageView.image = UIImage(named: "coin_img_30")
            self.productID = "muthos.coins.35000"
        case 3:
            imageView.image = UIImage(named: "coin_img_50")
            self.productID = "muthos.coins.60000"
        case 4:
            imageView.image = UIImage(named: "coin_img_100")
            self.productID = "muthos.coins.130000"
        default:
            break
        }
        
        actionButton.isEnabled = false
        getProductInfo()
        
        return imageView
    }
    
    //MARK: - Actions
    @IBAction func goPrev(_ sender: AnyObject) {
        self.dismiss(animated: true) { () -> Void in
            
        }
    }
    
    @IBAction func moveLeft(_ sender: AnyObject) {
        if carousel.currentItemIndex > 0 {
            carousel.scrollToItem(at: carousel.currentItemIndex-1, animated: true)
        }
    }
    
    @IBAction func moveRight(_ sender: AnyObject) {
        if carousel.currentItemIndex+1 < carousel.numberOfItems {
            carousel.scrollToItem(at: carousel.currentItemIndex+1, animated: true)
        }
    }
    
}
