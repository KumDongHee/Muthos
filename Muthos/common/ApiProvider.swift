//
//  ApiProvider.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 20..
//  Copyright © 2016년 김성재. All rights reserved.

import Foundation
import RxAlamofire
import KeychainAccess
import RxSwift
import Alamofire
import ObjectMapper
import SwiftyJSON
import FBSDKLoginKit

class ApiProvider {
    fileprivate static let AUTH_TOKEN = "x-auth-token"
    fileprivate static let AUTH_EMAIL = "x-auth-email"
    fileprivate static let AUTH_NICK = "x-auth-nick"
    internal static let BASE_URL:String = "http://api.muthos.net:31005"
    internal static let MODEL_BASE_URL = "http://api.muthos.net:31055"
    fileprivate static let DEFAULT_BOOK:String = "03_fairy/01_naked_emperor"
    fileprivate static let DEFAULT_COIN:Int = 500
    fileprivate static let keychain = Keychain(service: Bundle.main.bundleIdentifier as String!)
    
    static fileprivate func object_request<T: Mappable>(
        _ method: HTTPMethod,
        url: String,
        parameters: [String: AnyObject]?) -> Observable<(HTTPURLResponse, T)> {
        
        var header:[String: String] = [:]
        
        //token은 있으면 보냄
        if let token = keychain[AUTH_TOKEN] {
            header[AUTH_TOKEN] = token
        }
        
        return RxAlamofire.request(method, url, parameters: parameters)
            .flatMap{ $0
                .validate(statusCode: 200 ..< 300)
                .validate(contentType: ["application/json"])
                .rx_object()
        }
    }
    
    static fileprivate func plain_request(_ method: HTTPMethod, url: String,
                                      parameters: [String: AnyObject]?) -> Observable<DataRequest> {
        
        var header:[String: String] = [:]
        
        //token은 있으면 보냄
        if let token = keychain[AUTH_TOKEN] {
            header[AUTH_TOKEN] = token
        }
        
        return RxAlamofire.request(method, url, parameters: parameters, headers: header)
    }
    
    // 토큰 통한 로그인 확인
    static func isLogin() -> Bool {
        //email 로그인 확인
        //keychain에 token값이 있으면 무조건 오케?
        do {
            if let token = try keychain.getString(AUTH_TOKEN) , token.characters.count > 0 {
                return true
            } else {
                return false
            }
        } catch {
            return false
        }
    }
    
    static func loggedEmail() -> String {
        do {
            if let email = try keychain.getString(AUTH_EMAIL) {
                return email
            }
        } catch {
        }
        return ""
    }
    
    static func loggedNick() -> String {
        do {
            if let nick = try keychain.getString(AUTH_NICK) {
                return nick
            }
        } catch {
        }
        return ""
    }
    
    //토큰 받아오면 업데이트
    static func updateToken(_ acc:Account?) {
        guard acc != nil else {
            keychain[AUTH_TOKEN] = nil
            keychain[AUTH_EMAIL] = nil
            keychain[AUTH_NICK] = nil
            return
        }
        if let token = acc!.token {
            keychain[AUTH_TOKEN] = token
        }
        if let email = acc!.email {
            keychain[AUTH_EMAIL] = email
        }
        if let nick = acc!.nickname {
            keychain[AUTH_NICK] = nick
        }
    }
    
    static func loginWithEmail(_ account:[String: AnyObject]) -> Observable<(HTTPURLResponse, Account)> {
        var account = account
        for (key, _) in account {
            if !["email", "password"].contains(key) {
                account.removeValue(forKey: key)
            }
        }
        return object_request(.post, url: BASE_URL + "/login", parameters: account)
            .observeOn(MainScheduler.instance)
            .map { (response:HTTPURLResponse, accobj:Account) -> (HTTPURLResponse,Account) in
                self.updateToken(accobj)
                return (response,accobj)
        }
    }
    
    static func signUpWithEmail (_ account:[String: AnyObject]) -> Observable<(HTTPURLResponse, Account)> {
        var account = account
        for (key, _) in account {
            if !["email", "nickname", "gender", "password"].contains(key) {
                account.removeValue(forKey: key)
            }
        }
        return object_request(.post, url: BASE_URL + "/account", parameters: account)
            .observeOn(MainScheduler.instance)
            .map { (response:HTTPURLResponse, accobj:Account) -> (HTTPURLResponse,Account) in
                self.updateToken(accobj)
                return (response,accobj)
            }
    }
    
    static func logout() -> Observable<DataRequest> {
        //        FBSDKLoginManager().logOut()
        
        // server token 파기
        return plain_request(.post, url: BASE_URL+"/logout", parameters: nil)
            .observeOn(MainScheduler.instance)
            .map { (request) -> DataRequest in
                // local token 파기
                self.updateToken(nil)
                return request
        }
    }
    
    static func apiURL(_ req:String) -> URL {
        return URL(string: (ApiProvider.MODEL_BASE_URL + req).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)!
    }
    
    static func syncRequestJSON(_ req:String) -> JSON {
        do {
            let str:String = try String(contentsOf:ApiProvider.apiURL(req))
            return JSON.parse(str)
        } catch {
        }
        return JSON.parse("{}")
    }
    
    static func asyncLoadUserModel(_ callback:@escaping Async.callbackFunc = {() -> Bool in return true}) {
        DispatchQueue.global().async {
            let email:String = ApiProvider.loggedEmail()
            let str:String = ApiProvider.MODEL_BASE_URL + "/api/muthos/list/My?conditions={\"email\":\""+email+"\"}"
            let url:URL = URL(string: str.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)!
            do {
                let str:String = try String(contentsOf: url)
                let obj:JSON = JSON.parse("{\"list\":"+str+"}")
                let list:JSON = obj["list"]
                var json:JSON = list.count > 0 ? list[0] : ApiProvider.syncRequestJSON("/api/muthos/save/My?obj={\"email\":\""+email+"\",\"coin\":\""+String(DEFAULT_COIN)+"\"}")
                json.dictionaryObject!.removeValue(forKey: "__v")
                let user:User = try ApplicationContext.sharedInstance.userViewModel.currentUser.value()
                user.my = json
                user.email = email
                user.profileImage = UIImage(data:BookController.cachedResourceData("/pub/profiles/"+json["_id"].stringValue))
                user.name = loggedNick()
                ApplicationContext.sharedInstance.userViewModel.updateCash(user.getCoin())
                if user.isEmptyMyBooks() {
                    let book:Book = Book(JSON: ["_id":DEFAULT_BOOK])!
                    if user.appendBook(book) {
                        ApplicationContext.sharedInstance.userViewModel.updateUser(user)
                    }
                }
            } catch {
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
            }
            _ = callback()
        }
    }
    
    static func convertStringToDictionary(_ text: String) -> [String:AnyObject]? {
        if let data = text.data(using: String.Encoding.utf8) {
            do {
                var result = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject]
                result!["__v"] = nil
                return result
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
    
//    static func asyncSaveUserModel(_ user:User) {
//        let myId:JSON = (user.my?["_id"])!
//        var strMyId:String = ""
//
//        if myId.error == nil {
//            strMyId = "/" + myId.stringValue
//        }
//        
//        
//        var post = Dictionary<String, AnyObject>()
//        for (key, object) in user.my! {
//            post[key] = object as AnyObject
//        }
//        
//        //let encoded:String = str.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
//        let url:String = MODEL_BASE_URL+"/api/muthos/My"+strMyId
//        Alamofire.request(url, method: .post, parameters: post).responseJSON { response in
//        }
//    }

    
    static func asyncSaveUserModel(_ user:User) {
        let myId:JSON = (user.my?["_id"])!
        var strMyId:String = ""
        
        if myId.error == nil {
            strMyId = "/" + myId.stringValue
        }
        
        let post = convertStringToDictionary((user.my?.rawString())!)
        
        let url:String = MODEL_BASE_URL+"/api/muthos/save/My"+strMyId
        Alamofire.request(url, method: .post, parameters: post, encoding: JSONEncoding.default).responseJSON { response in
        }
    }
    
    
    static func purchaseSet(_ email:AnyObject, bookId:AnyObject, setIndex:AnyObject, callback:@escaping Async.callbackWithParam) {
        let params = ["email":email, "bookId":bookId, "setIndex":setIndex]
        let url = MODEL_BASE_URL+"/api/muthos/book/set/purchase"

        Alamofire.request(url,  method:.post, parameters:params).responseJSON { response in
            _ = callback(response.result.value! as AnyObject)
        }
    }
    
    static func earnPet(_ email:String, pet:String, callback:@escaping Async.callbackWithParam) {
        let params = ["email":email, "pet":pet]
        let url = MODEL_BASE_URL+"/api/muthos/pet/earn"
        print(url, params)
        Alamofire.request(url,  method:.post, parameters:params).responseJSON { response in
            if let v = response.result.value {
                _ = callback(v as AnyObject)
            }
        }
    }
    
    static func facebookLogin(fromViewController viewcontroller:UIViewController) {
        let permissions = ["public_profile", "email", "user_friends"]
        let login:FBSDKLoginManager = FBSDKLoginManager()
        login.logIn(
            withReadPermissions: permissions,
            from: viewcontroller,
            handler: {(loginResult: FBSDKLoginManagerLoginResult?, error: Error?) in
                guard let result = loginResult else { return }
                if error != nil {
                    FBSDKLoginManager().logOut()
                } else if result.isCancelled {
                    FBSDKLoginManager().logOut()
                } else {
                    let fbToken = result.token.tokenString
                    let fbUserID = result.token.userID

                    FBSDKAccessToken.current()
                    FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"email, name, gender"])
                        .start(completionHandler: {(conn:FBSDKGraphRequestConnection?, result:Any?, err:Error?) in
                            let result:NSDictionary = result as! NSDictionary
                            
                            keychain[AUTH_TOKEN] = fbToken
                            keychain[AUTH_NICK] = String(describing: result["name"]!)
                            
                            if let email = result.object(forKey: "email") as? String {
                                keychain[AUTH_EMAIL] = email
                            }
                            
                            var gender = result.object(forKey: "gender") as? String
                            if gender == nil {
                                gender = "None"
                            }
                            
                            let account = [
                                "email": keychain[AUTH_EMAIL]!,
                                "nickname": keychain[AUTH_NICK]!,
                                "gender": gender!,
                                "password": "yNK3H2cSBP"
                            ]
                            
                            let url = BASE_URL+"/account"
                            Alamofire.request(url, method:.post, parameters:account).responseJSON { response in
                                appDelegate.goMain()
                            }

                        })
                }
        })
    }
    
    static func sendReportMessage(type:String, message:String, callback:@escaping Async.callbackFunc) {
        let email = ApiProvider.loggedEmail()
        let params = ["from":email, "type":type, "message":message]
        let url = MODEL_BASE_URL+"/api/muthos/send/report"
        Alamofire.request(url,  method:.post, parameters:params).responseJSON { response in
            _ = callback()
        }
    }
}
