//
//  MyPageViewModel.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 17..
//
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyJSON
import Alamofire

class UserViewModel {
    let currentUser:BehaviorSubject<User>
    let currentFriends:BehaviorSubject<[User]>
    let currentLanguage:BehaviorSubject<LanguageMode>
    let currentAge:BehaviorSubject<AgeMode>
    let currentCash:BehaviorSubject<Int>
    let currentExp:BehaviorSubject<Int>
    
    init() {
        //로그인해서 사용자 정보 가져와야 함
        //우선 임시로 user생성

        let sampleFriends = [
            User(JSON: ["name":"아이린", "profileImage": UIImage(named: "friend01")!])!,
            User(JSON: ["name":"웬디",  "profileImage": UIImage(named: "friend02")!])!,
            User(JSON: ["name":"슬기", "profileImage": UIImage(named: "friend03")!])!,
            User(JSON: ["name":"조이", "profileImage": UIImage(named: "friend01")!])!,
            User(JSON: ["name":"예리", "profileImage": UIImage(named: "friend02")!])!]
        let sampleUserData = ["name":"아이린", "email":"irene@gmail.com"]
        let sampleUser = User(JSON: sampleUserData)!
        
        currentUser = BehaviorSubject(value: sampleUser)
        currentFriends = BehaviorSubject(value: sampleFriends)
        currentLanguage = BehaviorSubject(value: .korean)
        currentAge = BehaviorSubject(value: .all)
        currentCash = BehaviorSubject(value: 1000)
        currentExp = BehaviorSubject(value:0)
    }
    
    func updateUser(_ user:User) {
        ApiProvider.asyncSaveUserModel(user)
        currentUser.onNext(user)
    }
    
    func updateProfileImage(_ image:UIImage?) {
        do {
            let user = try currentUser.value()
            user.profileImage = image
            uploadProfileImage(image!, user:user)
            currentUser.onNext(user)
        } catch {}
    }
    
    func uploadProfileImage(_ image:UIImage, user:User) {
        // define parameters
        let parameters = [
            "path": "/uploaded/profiles/"+user.my!["_id"].stringValue
        ]
        
        // Begin upload
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                if let imageData = UIImageJPEGRepresentation(image, 1) {
                    multipartFormData.append(imageData, withName: "file")
                }
                for (key, value) in parameters {
                    multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
                }
            },
            to:ApiProvider.MODEL_BASE_URL+"/api/simple/upload",
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        debugPrint(response)
                    }
                case .failure(let encodingError):
                    print(encodingError)
                }
        })
    }
    
    func updateLanguage(_ language:LanguageMode) {
        currentLanguage.onNext(language)
    }
    
    func updateName(_ name:String?) {
        do {
            let user = try currentUser.value()
            if let name = name {
                user.name = name
                currentUser.onNext(user)
            }
        } catch {}
    }
    
    func updateAge(_ age:AgeMode) {
        currentAge.onNext(age)
    }
    
    func updateCash(_ cash:Int) {
        if let u = currentUserObject() {
            u.setCoin(cash)
            currentUser.onNext(u)
            currentCash.onNext(cash)
        }
    }
    
    func purchaseBook(_ book:Book) {
        if let user = currentUserObject() {
            if user.appendBook(book) {
                updateUser(user)
            }
        }
    }
    
    func currentUserObject() -> User? {
        do {
            let u = try currentUser.value()
            return u
        } catch{
        }
        return nil
    }
    
    func buildNotePath(_ bookId:String, setIndex:String, key:String) -> JSON {
        return JSON.parse("{\"bookId\":\""+bookId+"\",\"setIndex\":\""+setIndex+"\",\"key\":\""+key+"\"}")
    }
    
    func buildNotePath(_ bookId:String, setIndex:String) -> JSON {
        return buildNotePath(bookId, setIndex:setIndex, key:"")
    }
    
    func toggleMyNote(_ bookId:String, setIndex:String, key:String) {
        toggleMyNotePath(buildNotePath(bookId, setIndex:setIndex, key:key))
    }
    
    func hasMyNote(_ bookId:String, setIndex:String, key:String) -> Bool {
        if let user:User = currentUserObject() {
            if user.hasMyNoteWithPath(buildNotePath(bookId, setIndex:setIndex, key:key)) {
                return true
            }
        }
        return false
    }
    
    func toggleMyNotePath(_ path:JSON) {
        if let user:User = currentUserObject() {
            if user.toggleMyNotePath(path) {
                updateUser(user)
            }
        }
    }
    
    deinit {
        currentUser.onCompleted()
        currentFriends.onCompleted()
        currentLanguage.onCompleted()
        currentAge.onCompleted()
        currentCash.onCompleted()
    }
    
    /*  구매한 세트여부 반환  */
    func  hasSet(_ bookId:String, setIndex:String) -> Bool {
        if let user:User = currentUserObject() {
            if user.hasSet(bookId, setIndex:setIndex) {
                return true
            }
        }
        return false
    }
    
    /*  세트 구매 */
    /* Deprecated : 셋트 구매를 외부 연동으로 옮기면서 현재 사용 안함 */
    func  purchaseSet(_ bookId:String, setIndex:String) {
        if let user:User = currentUserObject() {
            if user.hasSet(bookId, setIndex:setIndex) {
                return
            }
            if user.appendSet(bookId, setIndex:setIndex) {
            }
        }
    }
    
    /*  세트 리쓴의 최근 사용 시간 */
    func  lastAccessForListen(_ bookId:String, setIndex:String) -> TimeInterval {
        if let user:User = currentUserObject() {
            return user.lastAccessForListen(bookId, setIndex: setIndex)
        }
        return 0
    }
    
    /*  세트 토크의 최근 사용 시간 */
    func  lastAccessForTalk(_ bookId:String, setIndex:String) -> TimeInterval {
        if let user:User = currentUserObject() {
            return user.lastAccessForTalk(bookId, setIndex: setIndex)
        }
        return 0
    }

    /*  세트의 최종 그레이드  */
    func  gradeForSetWithPath(_ bookId:String, setIndex:String, bookMode:BookMode = .easy) -> Int {
        if let user:User = currentUserObject() {
            return user.gradeForSetWithPath(bookId, setIndex:setIndex, bookMode:bookMode)
        }
        return 0
    }
    
    /*  코인 조회           */
    func  getCoin() -> Int {
        if let user:User = currentUserObject() {
            return user.getCoin()
        }
        return -1
    }
    
    /*  코인 추가           */
    func  appendCoin(_ coin:Int, memo:String) {
        if let user:User = currentUserObject() {
            let coin:Int = user.appendCoin(coin, memo:memo)
            updateUser(user)
            currentCash.onNext(coin)
        }
    }
    
    /*  코인 소진           */
    func  consumeCoin(_ coin:Int, memo:String) {
        if let user:User = currentUserObject() {
            user.consumeCoin(coin, memo:memo)
            updateUser(user)
        }
    }
    
    /*  코인 이력           */
    func  coinHistory() -> JSON {
        return JSON.parse("{}")
    }
    
    /*  리트라이 조회         */
    func  getRetry() -> Int {
        if let user:User = currentUserObject() {
            return user.getRetry()
        }
        return -1
    }
    
    /*  리트라이 추가         */
    func  appendRetry(_ retry:Int, memo:String) {
        if let user:User = currentUserObject() {
            user.appendRetry(retry, memo:memo)
            updateUser(user)
        }
    }
    
    /*  리트라이 소진         */
    func  consumeRetry(_ retry:Int, memo:String) {
        if let user:User = currentUserObject() {
            user.consumeRetry(retry, memo:memo)
            updateUser(user)
        }
    }
    
    /*  리트라이 이력         */
    func  retryHistory() -> JSON {
        return JSON.parse("{}")
    }
    
    /*  나의 펫 목록          */
    func  getPets() -> JSON {
        if let user:User = currentUserObject() {
            return user.getPets()
        }
        return JSON.parse("[]")
    }
    
    /*  펫 추가               */
    func  appendPetWithName(_ name:String) {
        if let user:User = currentUserObject() {
            user.appendPetWithName(name)
            updateUser(user)
        }
    }
    
    /*  펫 수확               */
    func  reapPet(_ pet:Pet) {
        if let user:User = currentUserObject() {
            user.reapPet(pet)
            updateUser(user)
        }
    }
    
    /*  마이노트의 그레이드   */
    func  gradeForMyNote(_ bookId:String, setIndex:String, key:String) -> Int {
        if let user:User = currentUserObject() {
            return user.gradeForMyNoteWithPath(buildNotePath(bookId, setIndex:setIndex, key:key))
        }
        return 0
    }
    
    /*  경험치 추가           */
    func  appendExp(_ exp:Int, memo:String) {
        if let user:User = currentUserObject() {
            user.appendExp(exp, memo:memo)
            updateUser(user)
            currentExp.onNext(exp)
        }
    }
    
    /*  현재 나의 경험치      */
    func  getExp() -> Int {
        if let user:User = currentUserObject() {
            return user.getExp()
        }
        return -1
    }
    
    /*  현재 다음 경험치       */
    func getNextExp() -> Int {
        if let user:User = currentUserObject() {
            return user.getNextExp()
        }
        return -1
    }
    
    
    /*  현재 나의 레벨        */
    func  getLevel() -> Int{
        if let user:User = currentUserObject() {
            return user.getLevel()
        }
        return -1
    }
    
    /* 해당 책의 최근 조회한 인덱스 저장 */
    func updateLastSet(_ bookId:String, index:Int) {
        guard let user:User = currentUserObject() else { return }
        user.updateLastSet(bookId, index:index)
        updateUser(user)
    }

    /* 책의 해당 세트의 최근 시퀀스 저장 */
    func updateLastSequence(bookId:String, setIndex: String, playMode:String, sequence: Int, bookMode:BookMode = .easy) {
        guard let user:User = currentUserObject() else { return }
        user.updateLastSequence(bookId:bookId, setIndex: setIndex, playMode:playMode, sequence: sequence, bookMode:bookMode)
        updateUser(user)
    }
    
    func lastSequence(bookId:String, setIndex: String, playMode:String, bookMode:BookMode = .easy) -> Int {
        guard let user:User = currentUserObject() else { return -1 }
        return user.lastSequence(bookId:bookId, setIndex: setIndex, playMode:playMode, bookMode:bookMode)
    }
    
    func writeScore(bookId:String, setIndex: String, bookMode:BookMode, key:String, grade:Int) {
        guard let user:User = currentUserObject() else { return }
        user.writeScore(bookId:bookId, setIndex: setIndex, bookMode:bookMode, key:key, grade:grade)
        updateUser(user)
    }
    
    func writeBonus(bookId:String, setIndex: String, bookMode:BookMode, key:String, grade:Int) {
        guard let user:User = currentUserObject() else { return }
        user.writeBonus(bookId:bookId, setIndex: setIndex, bookMode:bookMode, key:key, grade:grade)
        updateUser(user)
    }
    
    func appendPet(_ petName:String) {
        guard let user:User = currentUserObject() else { return }
        user.appendPet(petName)
        updateUser(user)
    }
    
    func hasCompletedPrioirSet(_ bookId:String, setIndex:String) -> Bool {
        guard let user:User = currentUserObject() else { return false}
        return user.hasCompletedPrioirSet(bookId, setIndex: setIndex)
    }
    
    func hasCompletedBookMode(_ bookId:String, setIndex:String, bookMode:BookMode) -> Bool {
        guard let user:User = currentUserObject() else { return false}
        return user.hasCompletedBookMode(bookId, setIndex: setIndex, bookMode:bookMode)
    }
    
    func hideFromMybook(_ bookId:String) {
        guard let user:User = currentUserObject() else { return }
        user.hideFromMybook(bookId)
        updateUser(user)
    }
    
    func updateGradeOnMyNote(path:JSON, grade:Int) {
        guard let user:User = currentUserObject() else { return }
        user.updateGradeOnMyNote(path:path, grade:grade)
        updateUser(user)
    }
}
