//
//  RouletteCont.swift
//  Muthos
//
//  Created by shining on 2016. 8. 20..
//
//

import UIKit
import CoreGraphics
import SwiftAnimations

protocol RouletteDelegate {
    func rouletteClosed(_ roulette:RouletteCont)
}

class RouletteCont : DefaultCont {
    static let CENTER_Y_OF_ICON:CGFloat = 80
    
    @IBOutlet var pin: UIImageView!
    @IBOutlet var rouletteWrap: UIView!
    @IBOutlet var message: UITextField!
    @IBOutlet weak var axis: UIView!
    @IBOutlet var startBtn: UIButton!
    @IBOutlet weak var resultArea: UIView!
    @IBOutlet weak var petName: UITextField!
    
    @IBOutlet weak var faceLight: UIImageView!
    @IBOutlet weak var faceLightBackground: UIImageView!
    
    @IBOutlet weak var petFace: UIImageView!
    
    @IBOutlet var abilityRows: [UIView]!
    
    @IBOutlet var roundedButtons: [UIButton]!
    @IBOutlet weak var resultMessage: UITextView!
    
    @IBOutlet weak var firstResultTitle: UITextField!
    @IBOutlet weak var firstResultValue: UITextField!
    
    @IBOutlet weak var secondResultTitle: UITextField!
    @IBOutlet weak var secondResultValue: UITextField!
    
    var controller:BookController?
    var rot:CGFloat = 0
    var rolling:Bool = false
    var rollDegree:CGFloat?
    var context:RouletteContext = RouletteContext()
    var delegate:RouletteDelegate?
    var lightRotating:Bool = false
    
    class RouletteContext {
        static let DEFAULT_ROLLING:Int = 18
        var list:[String] = []
        var win:Int = 0
        var roll:Int = 0
        
        init() {
            roll = RouletteContext.DEFAULT_ROLLING
        }
    }
    
    override func viewDidLoad() {
        self.edgesForExtendedLayout = UIRectEdge()
        initModel()

        _ = axis.circle()
        for i in 0...5 {
            addPie(i)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        for b:UIButton in roundedButtons {
            _ = b.circle().borderWith(UIColor.white, width: 1)
            b.imageView!.contentMode = .center
        }
        startBtn.isEnabled = true
        petFace.transform = CGAffineTransform.identity
    }
    
    override func viewDidLayoutSubviews() {
        var idx:Int = 0
        
        for v:UIView in rouletteWrap.subviews {
            let pc:PieCell = v as! PieCell
            pc.transform = CGAffineTransform(rotationAngle: 0)
            pc.frame = rouletteWrap.bounds
            pc.doLayout()
            
            let degree:CGFloat = CGFloat(idx) * pc.quotient
            pc.transform = CGAffineTransform(rotationAngle: degree)
            
            self.rollDegree = pc.quotient * -1
            
            idx += 1
        }
        rouletteWrap.setNeedsDisplay()
    }
    
    func initModel() {
        let PET_COUNT = 9
        let lvl = min(ApplicationContext.currentUser.getLevel(), PET_COUNT)
        
        context.list = ["coin/50", "pet/0"+String((lvl-2)), "coin/100",
                        "pet/0"+String((lvl-1)), "retry/10", "pet/0"+String((lvl))]
        
        context.win = Int(arc4random_uniform(5))
    }
    
    static let titleMap = ["coin":"Coin +##", "retry":"Retry +##", "pet":"Pet"]
    static let imageMap = ["coin":"bonus_icon_roulette_coin", "retry":"bonus_icon_roulette_retry", "pet":"pet_btn_##_02"]
    
    func addPie(_ idx:Int) {
        let arr:[String] = context.list[idx].components(separatedBy: "/")
        let type:String = arr[0]
        let param:String = arr[1]
        
        let pc:PieCell = PieCell(frame:rouletteWrap.bounds)
        pc.setNormalBackgroundColorFor(idx)
        self.rouletteWrap.addSubview(pc)
        
        let tf:UITextField = UITextField(frame:pc.outerWrap.bounds)
        tf.textAlignment = NSTextAlignment.center
        tf.text = RouletteCont.titleMap[type]?.replacingOccurrences(of: "##", with: param)
        tf.font = UIFont.systemFont(ofSize: 13)
        pc.outerWrap.addSubview(tf)
        
        let iv:UIImageView = UIImageView(frame:pc.innerWrap.bounds)
        iv.image = UIImage(named:(RouletteCont.imageMap[type]?.replacingOccurrences(of: "##", with: param))!)
        iv.contentMode = .scaleAspectFit
        iv.setCenterY(pc.innerWrap.height - RouletteCont.CENTER_Y_OF_ICON)
        pc.innerWrap.addSubview(iv)
    }
    
    let rollDuration:TimeInterval = 0.5

    @IBAction func onResultOK(_ sender: AnyObject) {
        self.hide()
    }
    
    func hide() {
        self.lightRotating = false
        self.resultArea.isHidden = true
        self.petFace.isHidden = true
        self.faceLight.isHidden = true
        self.faceLightBackground.isHidden = true
        self.faceLight.transform = CGAffineTransform(rotationAngle: 0)
        
        self.view.removeFromSuperview()
        if let d:RouletteDelegate = delegate {
            d.rouletteClosed(self)
        }
    }
    
    @IBAction func onStart(_ sender: AnyObject) {
        if rolling {
            return
        }
        startBtn.isEnabled = false
        rolling = true
        ApplicationContext.playEffect(code: .roulette)
        let pc:PieCell = self.rouletteWrap.subviews[self.context.win] as! PieCell
        pc.setNormalBackgroundColorFor(self.context.win)
        self.context.win = Int(arc4random_uniform(5))
        self.rouletteWrap.transform = CGAffineTransform(rotationAngle: 0)
        rot = -1 * rollDegree!
        rollWith(rot, curve:.curveEaseIn, duration:rollDuration).completion { (finish) -> Void in
            self.doRolling(self.context.roll-2-self.context.win)
        }
        tickPin()
    }
    
    func doRolling(_ n:Int) {
        if n <= 0 {
//            let rand:CGFloat = (CGFloat(arc4random_uniform(50)) / 100.0)
            rot -= rollDegree!
            self.rolling = false
            self.resultArea.layer.opacity = 0
            self.resultArea.isHidden = false
            self.petFace.isHidden = true
            self.faceLight.isHidden = true
            self.faceLightBackground.isHidden = true
            rollWith(rot, curve:.curveEaseOut, duration:rollDuration*1.5)
                .thenAnimate({
                    let pc:PieCell = self.rouletteWrap.subviews[self.context.win] as! PieCell
                    pc.setHighlighted()
                    pc.setNeedsDisplay()
                }).withOptions(UIViewAnimationOptions()).withDuration(0.5)
                .thenAnimate({
                    self.resultArea.layer.opacity = 1
                }).withOptions(UIViewAnimationOptions()).withDuration(0.5)
                .completion { (finish) -> Void in
                    self.startRotateLight()
                    self.startPetFaceAnimation()
            }
            
            return
        }
        rot -= rollDegree!
        rollWith(rot, curve:.curveLinear, duration:rollDuration/2).completion { (finish) -> Void in
                self.doRolling(n-1)
        }
    }
    
    func rollWith(_ degree:CGFloat, curve:UIViewAnimationOptions, duration:TimeInterval) -> Animator {
        return animate {
            self.rouletteWrap.transform = CGAffineTransform(rotationAngle: degree)
            }.withOptions(curve).withDuration(duration)
    }
    
    func tickPin() {
        if !rolling {return}
        animate {
            self.pin.transform = CGAffineTransform(rotationAngle: -0.5)
            }.withOptions(UIViewAnimationOptions()).withDuration(rollDuration/5)
            .thenAnimate({ _ -> Void in
                self.pin.transform = CGAffineTransform(rotationAngle: 0)
            }).withOptions(UIViewAnimationOptions()).withDuration(rollDuration/5)
            .completion { (finish) -> Void in
                self.tickPin()
        }
        
    }
    
    func prepareResultArea() {
        func doProcess(_ winStr:String) {
            let arr:[String] = winStr.components(separatedBy: "/")
            let key:String = arr[0]
            let value:String = arr[1]
            
            firstResultTitle.text = ""
            firstResultValue.text = ""
            secondResultTitle.text = ""
            secondResultValue.text = ""
            
            petFace.contentMode = .center
            
            if "pet" == key {
                let name:String = MypetCont.findPetNameForIndex(stringIndex: value)
                
                guard ApplicationContext.currentUser.hasPet(name) == false else {
                    doProcess("coin/50") ; return
                }
                
                petName.text = name.capitalized
                
                ApplicationContext.playEffect(code: .bonus)
                resultMessage.text = "축하합니다!\nPet 능력이 추가되었습니다."
                petFace.image = UIImage(named:"pet_btn_"+value+"_02")
                let abilities:[Int] = MypetCont.getAbilityIdx(name)
                
                if abilities.count > 0 {
                    firstResultTitle.text = MypetCont.getAbilityTitleOn(abilities[0])
                    firstResultValue.text = String(format:MypetCont.ABILITY_FORMATS[abilities[0]],
                                                   MypetCont.getPetAbilityItemBy(name, idx:abilities[0]))
                }
                if abilities.count > 1 {
                    secondResultTitle.text = MypetCont.getAbilityTitleOn(abilities[1])
                    secondResultValue.text = String(format:MypetCont.ABILITY_FORMATS[abilities[1]],
                                                    MypetCont.getPetAbilityItemBy(name, idx:abilities[1]))
                }
                
                ApplicationContext.sharedInstance.userViewModel.appendPet(name)
            }
            else if "coin" == key {
                petName.text = "Coin"
                resultMessage.text = "축하합니다!\nCoin이 추가되었습니다."
                petFace.image = UIImage(named:"pet_icon_coin_01")
                firstResultTitle.text = "Coin"
                firstResultValue.text = "+" + value
                ApplicationContext.playEffect(code: .coin)
                ApplicationContext.sharedInstance.userViewModel.appendCoin(Int(value)!, memo: "")
            }
            else if "retry" == key {
                petName.text = "Retry"
                resultMessage.text = "축하합니다!\nRetry가 추가되었습니다."
                petFace.image = UIImage(named:"pet_icon_retry_01")
                firstResultTitle.text = "Retry"
                firstResultValue.text = "+" + value
                ApplicationContext.playEffect(code: .coin)
                ApplicationContext.sharedInstance.userViewModel.appendRetry(Int(value)!, memo: "")
            }
        }
        
        doProcess(context.list[context.win])
    }
    
    func updateCompleted() {
        let bookId:String = controller!.book!._id!
        let setIndex:String = controller!.model!["sets"][controller!.selectedIdx!]["index"].stringValue
        let bookMode = controller!.bookMode
        let user = ApplicationContext.currentUser
        
        guard let _ = user.validateMinimalBookSet(bookId, setIndex: setIndex) else { return }

        let bookIdx = user.findBookIdxById(bookId)
        let setIdx = user.findBookSetIdx(bookId, setIndex:setIndex)
        let bookModeIdx = user.findBookModeIdx(bookId, setIndex:setIdx, bookMode:bookMode)

        user.my!["books"][bookIdx]["sets"][setIdx]["modes"][bookModeIdx]["params"]["completed"].intValue = 1

        ApiProvider.asyncSaveUserModel(user)
        print(user.my!)
    }
    
    func startPetFaceAnimation() {
        prepareResultArea()
        
        updateCompleted()
        
        self.petFace.layer.opacity = 0
        self.petFace.isHidden = false
        self.faceLight.layer.opacity = 0
        self.faceLight.isHidden = false
        self.faceLightBackground.layer.opacity = 0
        self.faceLightBackground.isHidden = false

        self.petFace.transform = self.petFace.transform.scaledBy(x: 0.1, y: 0.1)
        animate {
            self.petFace.layer.opacity = 1
            self.faceLight.layer.opacity = 1
            self.faceLightBackground.layer.opacity = 1
            self.petFace.transform = self.petFace.transform.scaledBy(x: 30, y: 30)
        }.withOptions(.curveEaseOut).withDuration(0.3)
            .thenAnimate({
                self.petFace.transform = self.petFace.transform.scaledBy(x: 0.4, y: 0.4)
            }).withOptions(.curveEaseOut).withDuration(0.2)
            .completion({(finish) -> Void in
            })
    }
    
    func startRotateLight() {
        self.lightRotating = true
        self.rot = 0
        self.faceLight.transform = CGAffineTransform(rotationAngle: self.rot)
        doRotateLight()
    }
    
    func doRotateLight() {
        let duration:TimeInterval = 2
        if self.lightRotating == false {
            return
        }
        animate {
            self.rot += 1
            self.faceLight.transform = CGAffineTransform(rotationAngle: self.rot)
            self.faceLight.layer.opacity = 0.3
            }.withOptions(.curveLinear).withDuration(duration)
            .thenAnimate({
                self.rot += 1
                self.faceLight.transform = CGAffineTransform(rotationAngle: self.rot)
                self.faceLight.layer.opacity = 1
            }).withOptions(.curveLinear).withDuration(duration)
            .completion {(finish) -> Void in
                self.doRotateLight()
        }
    }
    
    class PieCell : UIView {
        static let WIDTH_OF_OUT:CGFloat = 46
        static let DEFAULT_DIVISOR:CGFloat = 6
        
        var _divisor:CGFloat = 0
        var quotient:CGFloat = 0
        var divisor:CGFloat {
            get {
                return _divisor
            }
            set {
                _divisor = newValue
                quotient = CGFloat(2*Double.pi) / _divisor
                self.doLayout()
            }
        }
        
        let outerWrap:UIView = UIView(frame:CGRect(x: 0,y: 0,width: 0,height: 0))
        let innerWrap:UIView = UIView(frame:CGRect(x: 0,y: 0,width: 0,height: 0))
        var innerColor:CGColor = UIColor.gray.cgColor
        var outerColor:CGColor = UIColor.white.cgColor
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.doInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder:aDecoder)
        }
        
        func doInit() {
            self.backgroundColor = UIColor.clear
            outerWrap.backgroundColor = UIColor.clear
            innerWrap.backgroundColor = UIColor.clear
            addSubview(outerWrap)
            addSubview(innerWrap)

            self.divisor = PieCell.DEFAULT_DIVISOR
        }
        
        func doLayout() {
            let INNER_PADING:CGFloat = 20
            
            let rect:CGRect = self.bounds
            let center:CGPoint = CGPoint(x: rect.midX, y: rect.midY)
            let outR:CGFloat = min(rect.height, rect.width) / 2
            let inR:CGFloat = outR - PieCell.WIDTH_OF_OUT
            
            let beginAngle:CGFloat = CGFloat(Double.pi / 2) * -1 + quotient/2
            let endAngle:CGFloat = beginAngle-quotient

            let outLeft:CGPoint = PieCell.pointForAngle(center, r:outR, a:beginAngle)
            let outRight:CGPoint = PieCell.pointForAngle(center, r:outR, a:endAngle)
            
            outerWrap.frame = CGRect(x: outLeft.x, y: 0, width: outRight.x - outLeft.x, height: outR - inR)

            let inLeft:CGPoint = PieCell.pointForAngle(center, r:inR, a:beginAngle)
            let inRight:CGPoint = PieCell.pointForAngle(center, r:inR, a:endAngle)
            
            innerWrap.frame = CGRect(x: inLeft.x + INNER_PADING, y: outR - inR, width: inRight.x - inLeft.x - INNER_PADING*2, height: inR - INNER_PADING*2)
            
            PieCell.equalizeSubviews(outerWrap)
            PieCell.equalizeSubviews(innerWrap)
            
            self.setNeedsLayout()
        }
        
        static func equalizeSubviews(_ view:UIView) {
            for v:UIView in view.subviews {
                v.frame = view.bounds
            }
        }
        
        func setHighlighted() {
            innerColor = UIColor.init(hexString: "4aacff").cgColor
            outerColor = UIColor.init(hexString: "3a9cef").cgColor
            if outerWrap.subviews.count > 0 {
                (outerWrap.subviews[0] as! UITextField).textColor = UIColor.white
            }
            self.setNeedsDisplay()
        }
        
        func setNormalBackgroundColorFor(_ idx:Int) {
            if idx % 2 == 0 { setEven() }
            else { setOdd() }
        }
        
        func setOdd() {
            innerColor = UIColor.init(hexString: "ffffff").cgColor
            outerColor = UIColor.init(hexString: "f0f0f0").cgColor
            if outerWrap.subviews.count > 0 {
                (outerWrap.subviews[0] as! UITextField).textColor = UIColor.black
            }
            self.setNeedsDisplay()
        }
        
        func setEven() {
            innerColor = UIColor.init(hexString: "f0f0f0").cgColor
            outerColor = UIColor.init(hexString: "e0e0e0").cgColor
            if outerWrap.subviews.count > 0 {
                (outerWrap.subviews[0] as! UITextField).textColor = UIColor.black
            }
            self.setNeedsDisplay()
        }
        
        override func draw(_ rect:CGRect)
        {
            let ctx:CGContext = UIGraphicsGetCurrentContext()!
            
            let center:CGPoint = CGPoint(x: rect.midX, y: rect.midY)
            let outR:CGFloat = min(rect.height, rect.width) / 2
            let inR:CGFloat = outR - PieCell.WIDTH_OF_OUT
            
            let quotient:CGFloat = CGFloat(2*Double.pi) / divisor
            let beginAngle:CGFloat = CGFloat(Double.pi / 2) * -1 + quotient/2
            let endAngle:CGFloat = beginAngle-quotient
            
            PieCell.drawPie(ctx, c:center, r:outR, begin:beginAngle, end:endAngle, fill:outerColor)
            PieCell.drawPie(ctx, c:center, r:inR, begin:beginAngle, end:endAngle, fill:innerColor)
        }

        static func drawPie(_ ctx:CGContext, c:CGPoint, r:CGFloat, begin:CGFloat, end:CGFloat, fill:CGColor) {
            let p1:CGPoint = PieCell.pointForAngle(c, r:r, a:begin)
            ctx.setFillColor(fill)
            ctx.move(to: CGPoint(x: c.x, y: c.y))
            ctx.addLine(to: CGPoint(x: p1.x, y: p1.y))
            ctx.addArc(center: c, radius: r, startAngle: begin, endAngle: end, clockwise: true)

            ctx.closePath()
            ctx.drawPath(using: CGPathDrawingMode.fill)
        }
        
        static func pointForAngle(_ c:CGPoint, r:CGFloat, a:CGFloat) -> CGPoint {
            return CGPoint(x: CGFloat(c.x + r * CGFloat(cosf(Float(a)))),
                               y: CGFloat(c.y + r * CGFloat(sinf(Float(a)))))

        }
    }
}
