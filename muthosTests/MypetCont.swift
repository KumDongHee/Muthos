//
//  Mypet.swift
//  muthos
//
//  Created by YoungjuneKwon on 2016. 6. 22..
//
//

import UIKit
import SwiftyJSON

class MypetCont : DefaultCont, PetCellDelegate {
    static let PET_NAMES:[String] = ["pig", "frog", "rabbit", "panda", "racoon", "coala", "bear", "gorilla", "lion"]
    static let PET_MAP = [
        "pig"		:"01",
        "frog"		:"02",
        "rabbit"	:"03",
        "panda"		:"04",
        "racoon"	:"05",
        "coala"		:"06",
        "bear"		:"07",
        "gorilla"	:"08",
        "lion"		:"09"
    ]
    static let PET_ABILITIES = [
        ["pig", "0", "3", "0"],
        ["frog", "3", "0", "0"],
        ["rabbit", "0", "0", "10"],
        ["panda", "0", "5", "0"],
        ["racoon", "5", "0", "0"],
        ["coala", "0", "0", "15"],
        ["bear", "0", "7", "0"],
        ["gorilla", "7", "0", "0"],
        ["lion", "0", "0", "20"]
    ]
    static let ABILITY_TITLE = ["", "Set", "Retry", "Coin"]
    static let ABILITY_FORMATS = ["", "-%d%% DC", "+%d (4h)", "+%d (4h)"]
    static let COOLTIME_MAP:[String:Double] = [
        "pig":5,
        "rabbit":24,
        "panda":5,
        "coala":24,
        "bear":5,
        "lion":24
    ]

    static func findPetNameForIndex(stringIndex:String) -> String{
        for (k, v) in PET_MAP {
            if v == stringIndex {
                return k
            }
        }
        return ""
    }
    
    static func findPetAbilityBy(_ petName:String) -> [String] {
        for arr:[String] in PET_ABILITIES {
            if arr[0] == petName {
                return arr
            }
        }
        return ["","0","0","0"]
    }
    
    
    static func getPetAbilityItemBy(_ petName:String, idx:Int) -> Int {
        let arr = findPetAbilityBy(petName)
        return Int(arr[idx])!
    }
    
    static func getDcRateBy(_ petName:String) -> Int {
        return getPetAbilityItemBy(petName, idx:1)
    }

    static func getRetryBy(_ petName:String) -> Int {
        return getPetAbilityItemBy(petName, idx:2)
    }

    static func getCoinBy(_ petName:String) -> Int {
        return getPetAbilityItemBy(petName, idx:3)
    }
    
    static func getAbilityIdx(_ petName:String) -> [Int] {
        let arr = findPetAbilityBy(petName)
        var result:[Int] = []
        for i in 1...(arr.count-1) {
            guard Int(arr[i])! > 0 else { continue }
            result.append(i)
        }
        return result
    }
    
    static func getAbilityTitleOn(_ idx:Int) -> String {
        guard idx > 0 && idx < ABILITY_TITLE.count else {return ""}
        return ABILITY_TITLE[idx]
    }

    static func now() -> Double {
        return Date().timeIntervalSince1970 * 1000
    }

    static func cooltime(for petName:String) -> Double {
        if let hour:Double = COOLTIME_MAP[petName] {
            return hour * 60 * 60 * 1000
        }
        return 0
    }
    
    static func getEarnRate(_ petName:String) -> Float {
        guard let model = MypetCont.findMyPetModel(petName) else { return -1 }
        let arr = getAbilityIdx(petName)
        let last:Double = Double(model["lastEarned"].stringValue)!
        let current:Double = now()
        
        for a in arr {
            guard a > 1 else {continue}
            return Float((current - last) / cooltime(for:petName))
        }
        return -1
    }
    
    static func findMyPetModel(_ petName:String) -> JSON? {
        guard let my:JSON = ApplicationContext.currentUser.my else { return nil }
        guard my["pets"].error == nil else { return nil }
        let pets:JSON = my["pets"]
        
        for var p:JSON in pets.array! {
            if petName == p["name"].stringValue {
                return p
            }
        }
        
        return nil
    }
    
    @IBOutlet weak var selectedPetImg: UIImageView!
    @IBOutlet weak var selectedPetName: UITextField!
    @IBOutlet weak var firstAbilityTitle: UITextField!
    @IBOutlet weak var firstAbilityValue: UITextField!
    @IBOutlet weak var secondAbilityTitle: UITextField!
    @IBOutlet weak var secondAbilityValue: UITextField!
    
    @IBOutlet var cells: [UIView]!
    var petCells:[PetCell] = []
    var timer:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "My pet"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        initCells()
        timer = Timer.scheduledTimer(timeInterval: 1, target:self, selector: #selector(MypetCont.onTimer), userInfo: nil, repeats: true)
        evaluatePets()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if let timer = self.timer {
            timer.invalidate()
        }
    }
    
    override func touchLeftButton() {
        super.touchLeftButton()
        self.navigationController!.popViewController(animated: true)
    }
    
    func initCells() {
        for c:UIView in cells {
            guard c.subviews.count > 0 else {continue}
            _ = c.subviews[0].circle()
            (c.subviews[0] as! UIImageView).image = UIImage(named:"pet_btn_lock")
        }
    }
	
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let my:JSON = ApplicationContext.currentUser.my else { return }
        guard my["pets"].error == nil else { return }
        let pets:JSON = my["pets"]
        
        for p:JSON in pets.array! {
            guard p["name"].error == nil && p["lastEarned"].error == nil else { continue }
            let name = p["name"].stringValue
            guard let idx = MypetCont.PET_NAMES.index(of: name) else { continue }
            let pc:PetCell = PetCell.loadFromNib()
            pc.frame = cells[idx].bounds
            pc.name = name
            pc.initLayout()
            pc.delegate = self
            cells[idx].addSubview(pc)
            petCells.append(pc)
        }
        
        unSelectAll()
        if petCells.count > 0 {
            selectPet(petCells[0])
        }
    }
    
    func processEarning(_ cell:PetCell, callback:Async.callbackFunc) {
        let rate = MypetCont.getEarnRate(cell.name)
        if rate < 1 { _ = callback(); return }
        
        let user:User = ApplicationContext.currentUser
        let email:String = user.my!["email"].string!

        cell.startCoinAnimation()
        
        ApiProvider.earnPet(email, pet:cell.name, callback:{(any:AnyObject) -> Bool in
            ApiProvider.asyncLoadUserModel()
            
            cell.icon.isHidden = true
            
            for i in 0...(user.my!["pets"].count-1) {
                if cell.name == user.my!["pets"][i]["name"].stringValue {
                    user.my!["pets"][i]["lastEarned"].stringValue = String(MypetCont.now())
                }
            }
            ApplicationContext.playEffect(code: .coin)
            return true
        })
        _ = callback()
    }

    func selectPet(_ cell:PetCell) {
        unSelectAll()
        cell.selected = true

        selectedPetName.text = cell.name.capitalized
        guard (MypetCont.PET_MAP[cell.name] != nil) else { return }
        selectedPetImg.image = UIImage(named:"pet_img_"+MypetCont.PET_MAP[cell.name]!)
        
        firstAbilityTitle.text = ""
        firstAbilityValue.text = ""
        secondAbilityTitle.text = ""
        secondAbilityValue.text = ""
        
        let abilities:[Int] = MypetCont.getAbilityIdx(cell.name)
        if abilities.count > 0 {
            firstAbilityTitle.text = MypetCont.getAbilityTitleOn(abilities[0])
            firstAbilityValue.text = String(format:MypetCont.ABILITY_FORMATS[abilities[0]],
                                            MypetCont.getPetAbilityItemBy(cell.name, idx:abilities[0]))
        }
        if abilities.count > 1 {
            secondAbilityTitle.text = MypetCont.getAbilityTitleOn(abilities[1])
            secondAbilityValue.text = String(format:MypetCont.ABILITY_FORMATS[abilities[1]],
                                            MypetCont.getPetAbilityItemBy(cell.name, idx:abilities[1]))
        }
        
        cell.initLayout()
        processEarning(cell, callback:{() -> Bool in
            let rate = CGFloat(MypetCont.getEarnRate(cell.name))
            if rate >= 0 && rate < 1 {
                cell.progress.isHidden = false
                cell.time.isHidden = false
                self.onTimer()
            }
            return true
        })
    }
    
    func findSelectedCell() -> PetCell? {
        for p in petCells {
            if p.selected {
                return p
            }
        }
        return nil
    }
    
    func findCellFor(_ name:String) -> PetCell? {
        for p in petCells {
            if p.name == name {
                return p
            }
        }
        return nil
    }
    
    func onTimer() {
        evaluatePets()
    }
    
    func evaluatePets() {
        guard let my:JSON = ApplicationContext.currentUser.my else { return }
        guard my["pets"].error == nil else { return }
        let pets:JSON = my["pets"]
        
        for p:JSON in pets.array! {
            guard p["name"].error == nil && p["lastEarned"].error == nil else { continue }
            let name = p["name"].stringValue
            let rate = MypetCont.getEarnRate(name)
            
            if let pc = findCellFor(name) {
                if rate <= 0 {
                    pc.icon.isHidden = !pc.animating
                }
                else if rate > 0 && rate < 1 {
                    pc.progress.isHidden = pc.animating
                    pc.time.isHidden = pc.animating
                    let time = Double(rate) * MypetCont.cooltime(for:name)
                    let hour = Int(time / (1000 * 60 * 60))
                    let remain = time - Double(hour * 60 * 60 * 1000)
                    let min = Int(remain / (1000 * 60))
                    print(pc.name+", "+String(rate))
                    pc.hhmm = String(hour)+"h"+String(min)+"m"
                    pc.progress.rate = CGFloat(rate)
                } else {
                    pc.progress.isHidden = true
                    pc.time.isHidden = true
                    pc.icon.isHidden = false
                    let ab:[String] = MypetCont.findPetAbilityBy(name)
                    if Int(ab[3])! > 0 {
                        pc.icon.image = UIImage(named:"pet_icon_coin_01")
                    }
                    else if Int(ab[2])! > 0 {
                        pc.icon.image = UIImage(named:"pet_icon_retry_01")
                    }
                }
            }
        }
    }
    
    func unSelectAll() {
        for pc:PetCell in petCells {
            if pc.selected {
                pc.selected = false
                pc.initLayout()
            }
        }
    }
    
    func petcellDidSelected(_ cell:PetCell) {
        selectPet(cell)
    }
}
