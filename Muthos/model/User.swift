//
//  User.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 17..
//
//
import UIKit
import ObjectMapper
import SwiftyJSON

extension JSON{
    mutating func appendIfArray(_ json:JSON){
        if var arr = self.array{
            arr.append(json)
            self = JSON(arr);
        }
    }
    
    mutating func appendIfDictionary(_ key:String,json:JSON){
        if var dict = self.dictionary{
            dict[key] = json;
            self = JSON(dict);
        }
    }
}

class User: Mappable {
    var _id:String?
    var name:String?
    var email:String?
    var profileUrl:String?
    var profileImage:UIImage?
    var friends:[User]?
    var my:JSON? = JSON(parse:"{'books':[]}")
    
    required init?(map: Map) {
    }
    
    // Mappable
    func mapping(map: Map) {
        _id <- map["_id"]
        name <- map["name"]
        email <- map["email"]
        profileUrl <- map["profileUrl"]
        profileImage <- map["profileImage"]
    }
    
    func hasBook(_ book:Book) -> Bool { return hasBook(book._id!) }
    func hasBook(_ id:String) -> Bool {
        return findBookById(id)! != nil
    }
    
    func validateKey(_ key:String) -> JSON {
        if (my![key].error != nil) {
            my!.appendIfDictionary(key, json: "")
        }
        return my![key]
    }

    func validateArrayWith(_ key:String, json:JSON) -> JSON {
        var j:JSON = json
        if (j[key].error != nil) {
            j.appendIfDictionary(key, json: JSON.parse("[]"))
        }
        return j[key]
    }
    
    func validateArrayWith(_ key:String) -> JSON {
        return validateArrayWith(key, json:my!)
    }
    
    func validateMyBooks() -> JSON {
        return validateArrayWith("books")
    }
    
    func validateMyNotes() -> JSON {
        return validateArrayWith("my-notes")
    }
    
    func isEmptyMyBooks() -> Bool {
        return validateMyBooks().array!.count == 0
    }
    
    func appendBook(_ book:Book) -> Bool{
        if hasBook(book) { return false }
        my!["books"].appendIfArray(JSON.parse("{\"bookId\":\""+book._id!+"\",\"sets\":[]}"))
        return true
    }
    
    func findBookIdxById(_ bookId:String) -> Int {
        var result:Int = 0
        for var a in validateMyBooks().arrayValue {
            if a["bookId"].stringValue == bookId {
                return result
            }
            result += 1
        }
        return -1
    }
    
    func findBookById(_ bookId:String) -> JSON? {
        let idx = findBookIdxById(bookId)
        return idx >= 0 ? my!["books"][idx] : nil
    }

    func findBookSetsById(_ bookId:String) -> JSON? {
        if let b:JSON = findBookById(bookId) {
            return validateArrayWith("sets", json:b)
        }
        return nil
    }
    
    func findBookSetIdx(_ bookId:String, setIndex:String) -> Int {
        var result:Int = 0
        if let sets:JSON = findBookSetsById(bookId) {
            for s:JSON in sets.arrayValue {
                if s["index"].stringValue == setIndex {
                    return result
                }
                result += 1
            }
        }
        return -1
    }
    
    func findBookSet(_ bookId:String, setIndex:String) -> JSON? {
        let idx = findBookSetIdx(bookId, setIndex:setIndex)
        guard idx >= 0 else { return nil }
        guard let sets = findBookSetsById(bookId) else { return nil }
        return sets[idx]
    }
    
    func validateMinimalBookSet(_ bookId:String, setIndex:String) -> JSON? {
        let _ = appendSet(bookId, setIndex:setIndex)
        return findBookSet(bookId, setIndex:setIndex)
    }

    func findBookModeIdx(_ bookId:String, setIndex:Int, bookMode:BookMode) -> Int {
        guard let sets:JSON = findBookSetsById(bookId) else { return -1 }
        guard sets[setIndex].error == nil && sets[setIndex]["modes"].error == nil else { return -1 }

        let bookModeString = bookMode == .easy ? "easy" : "hard"
        var result:Int = 0
        
        for m:JSON in sets[setIndex]["modes"].arrayValue {
            if m["mode"].stringValue == bookModeString {
                return result
            }
            result += 1
        }
        
        return -1
    }
    
    func indexOfMyNotePath(_ path:JSON) -> Int {
        var idx:Int = 0
        for var a in validateMyNotes().array! {
            let p:JSON = a["path"]
            if path["bookId"].string! == p["bookId"].string!
                && path["setIndex"].string! == p["setIndex"].string!
                && path["key"].string! == p["key"].string! {
                return idx
            }
            idx += 1
        }
        return -1
    }
    
    func toggleMyNotePath(_ path:JSON) -> Bool {
        let idx = indexOfMyNotePath(path)
        if idx < 0 {
            let now:String = String((Date().timeIntervalSince1970) * 1000)
            let json:JSON = JSON.parse("{\"path\":"+(path.rawString()!)+", \"registed\":\""+now+"\", \"grade\":\"0\"}")
            my!["my-notes"].appendIfArray(json)
        }
        else {
            var array = my!["my-notes"].array!
            array.remove(at: idx)
            my!["my-notes"] = JSON(array)
        }
        return true
    }
    
    func hasMyNoteWithPath(_ path:JSON) -> Bool {
        let idx = indexOfMyNotePath(path)
        if idx < 0 {
            return false
        }
        return true
    }
    
    /*  구매한 세트여부 반환  */
    func  hasSetWithPath(_ path:JSON) -> Bool {
        return hasSet(path["bookId"].string!, setIndex:path["setIndex"].string!)
    }

    func hasSet(_ bookId:String, setIndex:String) -> Bool {
        if let sets:JSON = findBookSetsById(bookId) {
            for s:JSON in sets.array! {
                if s["index"].string! == setIndex {
                    return true
                }
            }
        }
        return false
    }
    
    /*  세트 추가 */
    func  appendSet(_ bookId:String, setIndex:String) -> Bool {
        if hasSet(bookId, setIndex:setIndex) {
            return false
        }
        
        let bookIdx = findBookIdxById(bookId)

        my!["books"][bookIdx]["sets"].appendIfArray(JSON(
                ["index":setIndex,
                    "modes":[
                        ["mode":"easy", "params":["last-access":0,"last-sequence":0,
                                                  "completed":0,"scoreBoard":[],"bonusBoard":[]]],
                        ["mode":"hard", "params":["last-access":0,"last-sequence":0,
                                                  "completed":0,"scoreBoard":[],"bonusBoard":[]]]
                    ],
                    "listen":["last-access":0,"last-sequence":0]]))
        return true
    }
    
    /*  세트 리쓴의 최근 사용 시간 */
    func  lastAccessForListen(_ bookId:String, setIndex:String) -> TimeInterval {
        if let set:JSON = findBookSet(bookId, setIndex:setIndex) {
            if (set["listen"].error == nil && set["listen"]["last-access"].error == nil) {
                return (set["listen"]["last-access"].doubleValue / 1000) as TimeInterval
            }
        }
        return 0
    }

    func findBookModeParams(_ bookId:String, setIndex:String, bookMode:BookMode) -> JSON? {
        let modeString = bookMode == .easy ? "easy" : "hard"
        guard let set:JSON = findBookSet(bookId, setIndex:setIndex) else { return nil }
        guard set["modes"].error == nil else { return nil }
        
        for m in set["modes"].arrayValue {
            guard m["mode"].error == nil else { continue }
            if m["mode"].stringValue == modeString
                && m["params"].error == nil
            {
                return m["params"]
            }
        }
        
        return nil
    }
    
    /*  세트 토크의 최근 사용 시간 */
    func  lastAccessForTalk(_ bookId:String, setIndex:String, bookMode:BookMode = .easy) -> TimeInterval {
        guard let params:JSON = findBookModeParams(bookId, setIndex:setIndex, bookMode:bookMode) else { return 0 }
        guard params["last-access"].error == nil else { return 0}
        return (params["last-access"].doubleValue / 1000) as TimeInterval
    }
    
    /*  세트의 최종 그레이드  */
    func  gradeForSetWithPath(_ bookId:String, setIndex:String, bookMode:BookMode = .easy) -> Int {
        let scoreBoard = findScoreBoard(bookId:bookId, setIndex:setIndex, bookMode:bookMode)
        guard scoreBoard != JSON.null else { return 0 }
        guard let params = findBookModeParams(bookId, setIndex:setIndex, bookMode:bookMode) else { return 0 }
        guard params["completed"].intValue == 1 else { return 0 }
        
        if params["last-grade"].error == nil { return params["last-grade"].intValue }
        
        var total = 0
        var score = 0
        for row in scoreBoard.arrayValue {
            guard row["grade"].error == nil else { continue }
            let idx:Int = row["grade"].intValue
            total += 1
            score += idx
        }
        
        return total > 0 ? (max(Int(((score * 100) / (total * 5)) / 20), 1)) : 5
    }
    
    /*  최근 사용한 세트 인덱스 */
    func  getLastSetIndex(_ bookId:String) -> Int {
        guard let json = findBookById(bookId) else { return 0}
        return json["last-set"].error == nil ? json["last-set"].intValue : 0
    }
    
    func setCoin(_ coin:Int) {
        _ = validateKey("coin")
        my!["coin"].intValue = coin
    }
    
    /*  코인 조회           */
    func  getCoin() -> Int {
        var coin:JSON = validateKey("coin")
        if "" == coin.stringValue {
            return 0
        }
        return coin.intValue
    }
    
    /*  코인 추가           */
    func  appendCoin(_ coin:Int, memo:String) -> Int {
        my!["coin"].intValue = (getCoin() + coin)
        return my!["coin"].intValue
    }
    
    /*  코인 소진           */
    func  consumeCoin(_ coin:Int, memo:String) {
        my!["coin"].intValue = (getCoin() - coin)
    }
    
    /*  코인 이력           */
    func  coinHistory() -> JSON {
        return JSON.parse("{}")
    }

    /*  리트라이 조회         */
    func  getRetry() -> Int {
        var retry:JSON = validateKey("retry")
        if "" == retry.stringValue {
            return 0
        }
        return retry.intValue
    }
    
    /*  리트라이 추가         */
    func  appendRetry(_ retry:Int, memo:String) {
        my!["retry"].intValue = (getRetry() + retry)
    }
    
    /*  리트라이 소진         */
    func  consumeRetry(_ retry:Int, memo:String) {
        my!["retry"].intValue = (getRetry() - retry)
    }
    
    /*  리트라이 이력         */
    func  retryHistory() -> JSON {
        return JSON.parse("{}")
    }
    
    /*  나의 펫 목록          */
    func  getPets() -> JSON {
        return validateArrayWith("pets")
    }
    
    /*  펫 추가               */
    func  appendPetWithName(_ name:String) {
        var pets:JSON = validateArrayWith("pets")
        pets.appendIfArray(JSON.parse("{name:\""+name+"\"}"))
    }
    
    /*  펫 수확               */
    func  reapPet(_ pet:Pet) {
    }

    /*  마이노트의 그레이드   */
    func  gradeForMyNoteWithPath(_ path:JSON) -> Int {
        return 0
    }
    
    /*  경험치 추가           */
    func  appendExp(_ exp:Int, memo:String) {
        my!["exp"].intValue = getExp() + exp
    }
    
    /*  현재 나의 경험치      */
    func  getExp() -> Int {
        return validateKey("exp").intValue
    }
    
    let EXP_PER_LVL = 10
    
    /*  현재 다음 경험치       */
    func getNextExp() -> Int {
        return (getLevel() + 1) * EXP_PER_LVL
    }
    
    /*  현재 나의 레벨        */
    func  getLevel() -> Int{
        return Int(getExp() / EXP_PER_LVL) + 1
    }
    
    /*  현재 나의 경험치 백분율 */
    func getExpRate() -> CGFloat {
        return CGFloat(getExp() % EXP_PER_LVL) / CGFloat(EXP_PER_LVL)
    }
    
    func  updateModel(_ json:JSON) {
        ApiProvider.asyncLoadUserModel()
    }
    
    func updateLastSet(_ bookId:String, index:Int) {
        let idx = findBookIdxById(bookId)
        guard idx >= 0 else { return }
        my!["books"][idx]["last-set"].intValue = index
    }
    
    /* 책의 해당 세트의 최근 시퀀스 저장 */
    func updateLastSequence(bookId:String, setIndex: String, playMode:String, sequence: Int, bookMode:BookMode = .easy) {
        let bookIdx = findBookIdxById(bookId)
        let setIdx = findBookSetIdx(bookId, setIndex:setIndex)
        let bookModeIdx = findBookModeIdx(bookId, setIndex:setIdx, bookMode:bookMode)
        guard bookIdx >= 0 && setIdx >= 0 && bookModeIdx >= 0 else { return }
        
        let timeInterval = Double(NSDate().timeIntervalSince1970) * 1000
        
        if playMode == "listen" {
            my!["books"][bookIdx]["sets"][setIdx]["listen"]["last-sequence"].intValue = sequence
            my!["books"][bookIdx]["sets"][setIdx]["listen"]["last-access"].doubleValue = timeInterval
        } else {
            my!["books"][bookIdx]["sets"][setIdx]["modes"][bookModeIdx]["params"]["last-sequence"].intValue = sequence
            my!["books"][bookIdx]["sets"][setIdx]["modes"][bookModeIdx]["params"]["last-access"].doubleValue = timeInterval
        }
    }

    func lastSequence(bookId:String, setIndex: String, playMode:String, bookMode:BookMode = .easy) -> Int {
        let bookIdx = findBookIdxById(bookId)
        let setIdx = findBookSetIdx(bookId, setIndex:setIndex)
        let bookModeIdx = findBookModeIdx(bookId, setIndex:setIdx, bookMode:bookMode)
        guard bookIdx >= 0 && setIdx >= 0 && bookModeIdx >= 0 else { return 0 }

        if playMode == "listen" {
            return my!["books"][bookIdx]["sets"][setIdx]["listen"]["last-sequence"].intValue
        }
        return my!["books"][bookIdx]["sets"][setIdx]["modes"][bookModeIdx]["params"]["last-sequence"].intValue
    }
    
    func writeScore(bookId:String, setIndex: String, bookMode:BookMode, key:String, grade:Int, board:String = "scoreBoard") {
        let bookIdx = findBookIdxById(bookId)
        let setIdx = findBookSetIdx(bookId, setIndex:setIndex)
        let bookModeIdx = findBookModeIdx(bookId, setIndex:setIdx, bookMode:bookMode)
        guard bookIdx >= 0 && setIdx >= 0 && bookModeIdx >= 0 else { return }
        
        var scoreIdx = 0
        for row in my!["books"][bookIdx]["sets"][setIdx]["modes"][bookModeIdx]["params"][board].arrayValue {
            if row["key"].stringValue == key {
                if my!["books"][bookIdx]["sets"][setIdx]["modes"][bookModeIdx]["params"][board][scoreIdx]["grade"].intValue < grade {
                    my!["books"][bookIdx]["sets"][setIdx]["modes"][bookModeIdx]["params"][board][scoreIdx]["grade"].intValue = grade
                }
                return
            }
            scoreIdx += 1
        }
        
        my!["books"][bookIdx]["sets"][setIdx]["modes"][bookModeIdx]["params"][board].appendIfArray(
            JSON([
                "key" : key,
                "grade" : grade
                ]))
    }
    
    func findScoreBoard(bookId:String, setIndex: String, bookMode:BookMode, board:String = "scoreBoard") -> JSON {
        guard let params = findBookModeParams(bookId, setIndex: setIndex, bookMode: bookMode) else { return JSON.null }
        return params[board].error == nil ? params[board] : JSON.null
    }
    
    func findScoreForKey(bookId:String, setIndex: String, bookMode:BookMode, key:String, board:String = "scoreBoard") -> JSON {
        let board = findScoreBoard(bookId: bookId, setIndex:setIndex, bookMode:bookMode, board:board)
        guard board != JSON.null else { return JSON.null }
        
        for row in board.arrayValue {
            guard row["grade"].error == nil else { continue }
            if row["key"].stringValue == key {
                return row
            }
        }
        
        return JSON.null
    }
    
    func writeBonus(bookId:String, setIndex: String, bookMode:BookMode, key:String, grade:Int) {
        writeScore(bookId:bookId, setIndex:setIndex, bookMode:bookMode, key:key, grade:grade, board:"bonusBoard")
    }
    
    func updateSetCompleted(bookId:String, setIndex: String, bookMode:BookMode, completed:Int) {
        let bookIdx = findBookIdxById(bookId)
        let setIdx = findBookSetIdx(bookId, setIndex:setIndex)
        let bookModeIdx = findBookModeIdx(bookId, setIndex:setIdx, bookMode:bookMode)
        guard bookIdx >= 0 && setIdx >= 0 && bookModeIdx >= 0 else { return }
        
        my!["books"][bookIdx]["sets"][setIdx]["modes"][bookModeIdx]["params"]["last-sequence"].intValue = 0
        my!["books"][bookIdx]["sets"][setIdx]["modes"][bookModeIdx]["params"]["completed"].intValue = completed
    }

    func isCompleted(bookId:String, setIndex: String, bookMode:BookMode) -> Bool {
        let bookIdx = findBookIdxById(bookId)
        let setIdx = findBookSetIdx(bookId, setIndex:setIndex)
        let bookModeIdx = findBookModeIdx(bookId, setIndex:setIdx, bookMode:bookMode)
        guard bookIdx >= 0 && setIdx >= 0 && bookModeIdx >= 0 else { return false }
        
        return my!["books"][bookIdx]["sets"][setIdx]["modes"][bookModeIdx]["params"]["completed"].intValue == 1
    }

    func updateLastGrade(bookId:String, setIndex: String, bookMode:BookMode, grade:Int) {
        let bookIdx = findBookIdxById(bookId)
        let setIdx = findBookSetIdx(bookId, setIndex:setIndex)
        let bookModeIdx = findBookModeIdx(bookId, setIndex:setIdx, bookMode:bookMode)
        guard bookIdx >= 0 && setIdx >= 0 && bookModeIdx >= 0 else { return }
        
        my!["books"][bookIdx]["sets"][setIdx]["modes"][bookModeIdx]["params"]["last-sequence"].intValue = 0
        my!["books"][bookIdx]["sets"][setIdx]["modes"][bookModeIdx]["params"]["last-grade"].intValue = grade
    }
    
    func lastGrade(bookId:String, setIndex: String, bookMode:BookMode) -> Int {
        let bookIdx = findBookIdxById(bookId)
        let setIdx = findBookSetIdx(bookId, setIndex:setIndex)
        let bookModeIdx = findBookModeIdx(bookId, setIndex:setIdx, bookMode:bookMode)
        guard bookIdx >= 0 && setIdx >= 0 && bookModeIdx >= 0 else { return 0 }
        
        return my!["books"][bookIdx]["sets"][setIdx]["modes"][bookModeIdx]["params"]["last-grade"].intValue
    }

    func pets() -> [JSON] {
        guard let my = my else { return [] }
        guard my["pets"].error == nil else { return [] }

        return my["pets"].arrayValue
    }
    
    func hasPet(_ petName:String) -> Bool {
        guard let my = my else { return false}
        guard my["pets"].error == nil else { return false }
        let pets:JSON = my["pets"]
        
        for p:JSON in pets.array! {
            guard p["name"].error == nil else { continue }
            if petName == p["name"].stringValue {
                return true
            }
        }
        return false
    }

    func appendPet(_ petName:String) {
        guard self.my != nil else { return }
        guard self.my!["pets"].error == nil else { return  }

        self.my!["pets"].appendIfArray(JSON(["name":petName, "lastEarned" : 0]))
    }
    
    func hasCompletedPrioirSet(_ bookId:String, setIndex:String) -> Bool {
        if setIndex == "1" { return true }
        guard let sets = findBookSetsById(bookId) else { return false }

        if let idx = Int(setIndex) {
            let prioir = String(idx - 1)
            for s:JSON in sets.arrayValue {
                if s["index"].stringValue == prioir {
                    for m:JSON in s["modes"].arrayValue {
                        if m["params"]["completed"].stringValue == "1" {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    
    func hasCompletedBookMode(_ bookId:String, setIndex:String, bookMode:BookMode) -> Bool {
        let bookIdx = findBookIdxById(bookId)
        let setIdx = findBookSetIdx(bookId, setIndex:setIndex)
        let bookModeIdx = findBookModeIdx(bookId, setIndex:setIdx, bookMode:bookMode)
        guard bookIdx >= 0 && setIdx >= 0 && bookModeIdx >= 0 else { return false}

        return my!["books"][bookIdx]["sets"][setIdx]["modes"][bookModeIdx]["params"]["completed"].intValue == 1
    }
    
    func getMybooks(library:[Book]) -> [Book] {
        var result:[Book] = []
        var mybooks:[JSON] = validateMyBooks().arrayValue
        for idx in 1...mybooks.count {
            let m:JSON = mybooks[mybooks.count - idx]
            guard m["hide"].stringValue != "true" else { continue }
            for b in library {
                guard let id = b._id else { continue }
                if id == m["bookId"].stringValue {
                    print(m["bookId"].stringValue)
                    result.append(b)
                }
            }
        }
        
        return result
    }
    
    func hideFromMybook(_ bookId:String) {
        let bookIdx = findBookIdxById(bookId)
        guard bookIdx >= 0 else { return }
        
        my!["books"].arrayObject?.remove(at: bookIdx)
//        my!["books"][bookIdx]["hide"].stringValue = "true"
    }
    
    func updateGradeOnMyNote(path:JSON, grade:Int) {
        let noteIdx = indexOfMyNotePath(path)
        guard noteIdx >= 0 else { return }
        my!["my-notes"][noteIdx]["grade"].intValue = grade
    }
}
