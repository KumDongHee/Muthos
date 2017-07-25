//
//  BookController.swift
//  Muthos
//
//  Created by Youngjune Kwon on 2016. 1. 30..
//  Copyright © 2016년 김성재. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import AVFoundation
import SVProgressHUD
import ObjectMapper
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}

extension String {
    func split(regex pattern: String) -> [String] {
        
        guard let re = try? NSRegularExpression(pattern: pattern, options: [])
            else { return [] }
        
        let nsString = self as NSString // needed for range compatibility
        let stop = "<SomeStringThatYouDoNotExpectToOccurInSelf>"
        let modifiedString = re.stringByReplacingMatches(
            in: self,
            options: [],
            range: NSRange(location: 0, length: nsString.length),
            withTemplate: stop)
        return modifiedString.components(separatedBy: stop)
    }
}

class BookController : NSObject {
    var bookMode:BookMode = .easy
    var muteSpeaker:Bool = false
    var model:JSON?
    var L:JSON?
    var recognizer:SpeechRecognizing?
    var bookSet:BookSet?
    var selectedIdx:Int? = 0
    var voicePlayer:AVPlayer = AVPlayer()
    var voiceCallback:Async.callbackFunc?
    var score:ScoreCont?
    var summary:SummaryCont?
    var roulette:RouletteCont?
    var situationCont:SituationCont?

    var book:Book? {
        didSet {
            muteSpeaker = false
            bookMode = .easy
            
            self.loadModel()
        }
    }

    override init() {
        super.init()

        self.recognizer = SpeechFrameworkRecognizer.instance()
        self.score = getScoreViewController()
        self.summary = getSummaryViewController()
    }
    
    convenience init(book:Book) {
        self.init()
        self.book = book
        self.loadModel()
    }
    
    deinit {
        print("BookController deinited, "+(self.book?._id)!)
    }
    
    func loadModel() {
        self.model = JSON(data:self.cachedBookResourceData("/content.json"))
        self.L = (model?["locale"]["kr"])!
    }
    
    func startRecognizing() {
    }
    
    func getSelectedListenModel() -> JSON {
        return (model?["sets"][selectedIdx!]["listen"])!
    }
    
    static func loadViewController(_ storyboard:String, viewcontroller:String) -> UIViewController {
        return UIStoryboard(name: storyboard, bundle: nil).instantiateViewController(withIdentifier: viewcontroller)
    }
    
    func getListenViewController() -> ListenCont {
        let cont = BookController.loadViewController("BookCommon", viewcontroller: "ListenCont") as! ListenCont
        cont.controller = self
        return cont
    }
    
    func getScoreViewController() -> ScoreCont {
        let cont = BookController.loadViewController("BookCommon", viewcontroller: "ScoreCont") as! ScoreCont
        cont.controller = self
        return cont
    }
    
    func getSummaryViewController() -> SummaryCont {
        let cont = BookController.loadViewController("BookCommon", viewcontroller: "SummaryCont") as! SummaryCont
        cont.controller = self
        return cont
    }
    
    func getTalkViewController() -> UIViewController {
        if let situationCont = situationCont {
            return situationCont
        }
        
        situationCont = BookController.loadViewController("Situation", viewcontroller: "SituationCont") as! SituationCont
        situationCont!.controller = self
        
        return situationCont!
    }
    
    func getRouletteController() -> RouletteCont {
        let cont = BookController.loadViewController("Roulette", viewcontroller: "RouletteCont") as! RouletteCont
        cont.controller = self
        return cont
    }
    
    static func findWordIn(_ array:[String], word:String, found:[NSInteger]) -> NSInteger {
        for (idx, w) in array.enumerated() {
            if word.caseInsensitiveCompare(w) == ComparisonResult.orderedSame {
                if found.index(of: idx) >= 0 {
                    continue
                }
                return idx
            }
        }
        return -1
    }
    
    static func prepareDesc(_ desc:String, flexibility:JSON) -> String {
        guard flexibility != JSON.null else { return desc }
        var result:String = String(desc)
        
        for (key,flexibles):(String, JSON) in flexibility {
            for f in flexibles.arrayValue {
                let str:String = f.stringValue
                let count:Int = str.characters.count

                if result.range(of: " " + str + " ") != nil {
                    result = result.replacingOccurrences(of: " " + str + " ", with: (" " + key + " "))
                }
                else if result.hasSuffix(" " + str) {
                    result = result.substring(to: result.index(result.endIndex, offsetBy:count * -1)) + String(" ") + key
                }
                else if result.hasPrefix(str + " ") {
                    result = key + " " + result.substring(from: result.index(result.startIndex, offsetBy:count))
                }
            }
        }
        
        return result
    }
    
    static func evaluateSentence(_ orig:String, desc:String, flexibility:JSON = JSON.null) -> JSON {
        let preparedDesc:String = BookController.prepareDesc(desc, flexibility:flexibility)
        
        let arrayOrig:[String] = orig.split(regex: "[ ]+")
        let arrayDesc:[String] = preparedDesc.split(regex: "[ ]+")
        var foundIdx:[NSInteger] = []
        var origResult:String = ""
        var descResult:String = ""
        let words:Int = arrayOrig.count
        var incorrects:Int = 0
        var score:Int = 0
        var grade:Int = 0
        var rawString:String = ""
        
        for (_, wordOrig) in arrayOrig.enumerated() {
            var replacedOrig:String = String(wordOrig)
            replacedOrig = replacedOrig.replacingOccurrences(of: "?", with: "")
            replacedOrig = replacedOrig.replacingOccurrences(of: "!", with: "")
            replacedOrig = replacedOrig.replacingOccurrences(of: ".", with: "")
            replacedOrig = replacedOrig.replacingOccurrences(of: ",", with: "")
            
            var found:NSInteger = 0
            
            found = findWordIn(arrayDesc, word: replacedOrig, found:foundIdx)
            
            if found >= 0 {
                origResult += wordOrig + " "
                foundIdx.append(found)
            }
            else {
                origResult += "<span style='color:red'>" + wordOrig + "</span> "
                incorrects += 1
            }
        }
        
        for (idx, wordDesc) in arrayDesc.enumerated() {
            if foundIdx.contains(idx) {
                descResult += wordDesc + " "
            } else {
                descResult += "<span style='color:red'>" + wordDesc + "</span> "
            }
        }
        
        score = (words - incorrects) * 100 / words
        
        grade = score / 20
        
        rawString += "{\"score\":"+String(score)+",\"words\":"+String(words)
        rawString += ",\"incorrects\":"+String(incorrects)
        rawString += ",\"grade\":"+String(grade)
        rawString += ",\"orig\":\""+origResult+"\""
        rawString += ",\"desc\":\""+descResult+"\"}"
        
        return JSON(data:rawString.data(using: String.Encoding.utf8)!)
    }
    
    func stopVoice() {
        voicePlayer.pause()
    }
    
    var flagPlayingVoice:Bool = false
    
    func playVoice(_ url:URL, callback:@escaping Async.callbackFunc) {
        self.voicePlayer.replaceCurrentItem(with: AVPlayerItem(url:url))
        self.voiceCallback = callback
        self.voicePlayer.play()
        self.flagPlayingVoice = true
        
        self.perform(#selector(BookController.setupObserver), with: nil, afterDelay: 0.5)
    }

    func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(BookController.onVoiceEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.voicePlayer.currentItem)

    }
    
    func onVoiceEnd(_ notification: Notification) {
        self.flagPlayingVoice = false
        
        NotificationCenter.default.removeObserver(self, name:NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.voicePlayer.currentItem)
        
        _ = self.voiceCallback!()
    }
    
    func bookResourceURL(_ resource:String) -> URL {
        return BookController.bookResourceURL(self.book!, resource:resource)
    }
    
    func bookResourcePath(_ resource:String) -> String {
        return BookController.bookResourcePath(self.book!, resource: resource)
    }
    
    static func bookResourcePath(_ book:Book, resource:String) -> String {
        return bookResourcePath(book._id!, resource:resource)
    }
    
    static func bookResourcePath(_ bookId:String, resource:String) -> String {
        return bookId+resource
    }
    
    static func bookResourceURL(_ book:Book, resource:String) -> URL {
        return bookResourceURL(book._id!, resource:resource)
    }

    static func bookResourceURL(_ bookId:String, resource:String) -> URL {
        return URL(string:ApiProvider.BASE_URL+"/res/books/"+bookId+resource)!
    }

    func prepareResourcePath(_ resource:String) -> URL? {
        return BookController.prepareResourcePath(self.book!, resource: resource)
    }
    
    static func prepareResourcePath(_ book:Book, resource:String) -> URL? {
        return prepareResourcePath(book._id!, resource:resource)
    }
    
    static func prepareResourcePath(_ bookId:String, resource:String) -> URL? {
        if resource == "" {
            return nil
        }
        let fullPath = BookController.documentRoot()
            .appendingPathComponent("res/books/"+bookResourcePath(bookId, resource:resource))
        let directoryPath = (fullPath.path.substring(to: (fullPath.path.range(of: "/", options: .backwards)?.lowerBound)!))
        if FileManager.default.fileExists(atPath: directoryPath) {return fullPath}
        do {
            print("createDirectory, "+directoryPath)
            try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription);
        }
        return fullPath
    }

    static func prepareResourcePath(_ resource:String) -> URL? {
        if resource == "" {
            return nil
        }
        let fullPath = BookController.documentRoot().appendingPathComponent(resource)
        let directoryPath = (fullPath.path.substring(to: (fullPath.path.range(of: "/", options: .backwards)?.lowerBound)!))
        if FileManager.default.fileExists(atPath: directoryPath) {return fullPath}
        do {
            print("createDirectory, "+directoryPath)
            try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription);
        }
        return fullPath
    }
    
    func cachedBookResourceData(_ resource:String) -> Data {
        return BookController.cachedBookResourceData(self.book!, resource: resource)
    }
    
    static func cachedBookResourceData(_ book:Book, resource:String) -> Data {
        return cachedBookResourceData(book._id!, resource:resource)
    }
    
    static func cachedBookResourceData(_ bookId:String, resource:String, forceDownload:Bool = false) -> Data {
        if let url:URL = BookController.cachedBookResourceURL(bookId, resource: resource, forceDownload:forceDownload) {
            let data:Data = try! Data(contentsOf: url)
            return data
        }
        return Data()
    }

    static func cachedResourceData(_ resource:String) -> Data {
        if let url:URL = BookController.cachedResourceURL(resource) {
            let data:Data = try! Data(contentsOf: url)
            return data
        }
        return Data()
    }
    
    func cachedBookResourceURL(_ resource:String) -> URL? {
        return BookController.cachedBookResourceURL(self.book!, resource: resource)
    }
    
    static func cachedBookResourceURL(_ book:Book, resource:String) -> URL? {
        return cachedBookResourceURL(book._id!, resource:resource)
    }
    
    static func cachedBookResourceURL(_ bookId:String, resource:String, forceDownload:Bool = false) -> URL? {
        let fullPath:URL = BookController.documentRoot().appendingPathComponent("/res/books/"+bookId+resource)
        let fullPathString:String = fullPath.path
        if forceDownload != true && FileManager.default.fileExists(atPath: fullPathString) {
            return fullPath
        }
        else {
            let url:URL = bookResourceURL(bookId, resource:resource)
            do {
                let data:Data = try Data(contentsOf: url)
                _ = prepareResourcePath(bookId, resource:resource)
                try? data.write(to: URL(fileURLWithPath: fullPathString), options: [.atomic])
                return fullPath
            } catch {
                return nil
            }
        }
    }

    static func cachedResourceURL(_ resource:String) -> URL? {
        let fullPath:URL = BookController.documentRoot().appendingPathComponent(resource)
        let fullPathString:String = fullPath.path
        if FileManager.default.fileExists(atPath: fullPathString) {
            return fullPath
        }
        else {
            let url:URL = URL(string:ApiProvider.BASE_URL+resource)!
            if let data:Data = try? Data(contentsOf: url) {
                _ = prepareResourcePath(resource)
                try? data.write(to: URL(fileURLWithPath: fullPathString), options: [.atomic])
                return fullPath
            }
        }
        return nil
    }

    func showSummaryOn(_ parent:UIView) {
        summary!.showOn(parent)
    }
    
    func showScoreOn(_ parent:UIView) {
        self.showScoreOn(parent, onClose:nil)
    }
    
    func showScoreOn(_ parent:UIView, onClose:Async.callbackFunc?) {
        score!.view.isHidden = false
        score!.onClose = onClose
        parent.addSubview(score!.view)
        score!.reload()
        print(score!.view.frame)
    }
    
    func hideScore() {
        score!.view.removeFromSuperview()
    }
    
    func showRouletteOn(_ parent:UIViewController) {
        if roulette == nil {
            roulette = getRouletteController()
        }

        var frame:CGRect = parent.view.bounds
        frame.origin.y = parent.topLayoutGuide.length
        frame.size.height -= parent.topLayoutGuide.length
        roulette!.view.frame = frame
        parent.view.addSubview(roulette!.view)
    }
    
    static func displaySetMainOn(_ current:UIViewController, book:Book) {
        let cont = BookController.loadViewController("Main", viewcontroller: "SetMainCont") as! SetMainCont
        cont.book = book
        current.navigationController?.pushViewController(cont, animated: false)
    }
    
    func hideRoulette() {
        roulette!.hide()
    }
    
    func isRouletteShown() -> Bool {
        return roulette != nil && roulette!.view.superview != nil
    }
    
    func evaluateScoreModel() -> Dictionary<String, AnyObject> {
        var result:Dictionary<String, AnyObject> = [:]
        var grades:[Int] = [0,0,0,0,0,0,0,0,0,0]
        var total:Int = 0
        var score:Int = 0
        var retry:Int = 0

        let setIndex = model!["sets"][selectedIdx!]["index"].stringValue
        
        guard let book = self.book else { return result }
        let scoreBoard = ApplicationContext.currentUser.findScoreBoard(
            bookId:book._id!, setIndex:setIndex, bookMode:bookMode)
        guard scoreBoard != JSON.null else { return result }
        
        for row in scoreBoard.arrayValue {
            guard row["grade"].error == nil else { continue }
            let idx:Int = row["grade"].intValue
            grades[idx] += 1
            total += 1
            score += idx
        }

        let grade:Int = total > 0 ? (max(Int(((score * 100) / (total * 5)) / 20), 1)) : 5

        let bonusBoard = ApplicationContext.currentUser.findScoreBoard(
            bookId:book._id!, setIndex:setIndex, bookMode:bookMode, board:"bonusBoard")

        if bonusBoard != JSON.null {
            for row in bonusBoard.arrayValue {
                guard row["grade"].error == nil else { continue }
                retry += row["grade"].intValue
            }
        }

        if total == 0 {
            total = 1
            grades[5] = 1
        }
        
        result["retry"] = retry as AnyObject?
        result["grade"] = grade as AnyObject?
        result["coin"] = BookController.coinRewardFor(grade) as AnyObject?
        result["counts"] = grades as AnyObject?
        result["total"] = total as AnyObject?
        
        return result
    }
    
    func findDialogByKey(_ key:String) -> JSON? {
        let KEY:String = "voice"
        let json:JSON = getSelectedListenModel()
        let dialogs:[JSON] = json["dialogs"].array!
        for d in dialogs {
            if key == d[KEY].string! {
                return d
            }
        }
        return nil
    }
    
    func writeScore(_ key:String, grade:Int) {
        if let book:Book = self.book {
            ApplicationContext.sharedInstance.userViewModel.writeScore(
                bookId: book._id!, setIndex: model!["sets"][selectedIdx!]["index"].stringValue,
                bookMode: bookMode, key: key, grade: grade)
        }
    }
    
    func writeBonus(_ key:String, grade:Int) {
        if let book:Book = self.book {
            ApplicationContext.sharedInstance.userViewModel.writeBonus(
                bookId: book._id!, setIndex: model!["sets"][selectedIdx!]["index"].stringValue,
                bookMode: bookMode, key: key, grade: grade)
        }
    }
    
    func downloadResource(
        forSetIndexes indexes:[Int] = [],
        onStarted:@escaping Async.callbackFunc = {() -> Bool in return true },
        onProgress:@escaping Async.callbackWithParam = {(_:AnyObject) -> Bool in return true })
    {
        let resource:[String] = buildResourceArray(indexes)
        var toDownload:Bool = false
        for r in resource {
            let fullPath = self.prepareResourcePath(r)
            if FileManager.default.fileExists(atPath: fullPath!.path) {continue}
            toDownload = true
            break
        }
        if !toDownload { _ = onStarted();_ = onProgress([1,1] as AnyObject);return }
        var idx:Int = 0
        Async.eachSeries(
            resource as [AnyObject],
            eachFunc:{(any:AnyObject, nxt:@escaping Async.callbackFunc) -> Void in
                let r:String = String(describing: any)
                self.downloadEachResource(r, callback: {() -> Bool in
                    idx = idx + 1
                    _ = onProgress([idx, resource.count] as AnyObject)
                    _ = nxt()
                    return true
                })
        }, callback:{() -> Bool in
            return true
        })
        _ = onStarted()
    }
    
    
    func buildResourceArray(_ indexes:[Int]) -> [String] {
        var array:[String] = []
        let STRING_TYPES:[String] = ["video-sync","video","bgm","sound"]
        let KEY_TYPES:[String] = ["narration","quote","speech"]
        if let sets = self.model!["sets"].arrayObject {
            for any in sets {
                let st:JSON = JSON(any)
                if indexes.count > 0 && !indexes.contains(st["index"].intValue)  {
                    continue
                }
                let seqs = [
                    st["talk"]["sequence"].arrayObject,
                    st["talk"]["modes"]["easy"].arrayObject,
                    st["talk"]["modes"]["hard"].arrayObject
                    ]
                for seq in seqs {
                    guard let seq = seq else { continue }
                    for sq in seq {
                        let s:JSON = JSON(sq)
                        let type:String = s["type"].string!
                        if STRING_TYPES.index(of: type) >= 0 {
                            array.append(s["params"].string!)
                        }
                        else if KEY_TYPES.index(of: type) >= 0 {
                            array.append(s["params"]["dialog-key"].string!)
                        }
                    }
                }
                if let dig = st["listen"]["dialogs"].arrayObject {
                    for dg in dig {
                        let d:JSON = JSON(dg)
                        if let p:String = d["voice"].string {
                            array.append(p)
                        }
                    }
                }
            }
            /* 전체 셋트의 커버이미지와 스피커 이미지 내려받음 */
            for any in sets {
                let st:JSON = JSON(any)
                if st["coverImage"].error == nil {
                    array.append(st["coverImage"].stringValue)
                }
                if st["speakerImage"].error == nil {
                    array.append(st["speakerImage"].stringValue)
                }
            }
        }
        
        if let set = self.model!["set"].arrayObject {
            for any in set {
                let st:JSON = JSON(any)
                var arr:[String] = [st["content"]["bgm"].string!,
                                    st["content"]["videos"]["situation"].string!,
                                    st["question"]["voice"].string!
                ]
                for an in st["content"]["videos"]["waitings"].arrayObject! {
                    arr.append(an as! String)
                }
                
                for any in arr {
                    let r:String = String(any)
                    if r == "" {continue}
                    array.append(r)
                }
            }
        }

        return array
    }
    
    func downloadEachResource(_ r:String, callback:@escaping Async.callbackFunc) {
        let fullPath = self.prepareResourcePath(r)
        if FileManager.default.fileExists(atPath: fullPath!.path) { _=callback(); return }
        Alamofire.download(
            self.bookResourceURL(r).absoluteString,
            to:{ _, _ -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in return (fullPath!, [.removePreviousFile, .createIntermediateDirectories])})
            .response { response in
                print(response)
                _=callback()
        }
    }
    
    func waitForResource(_ resource:String, callback:@escaping Async.callbackFunc) {
        let fullPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("res/books/"+self.bookResourcePath(resource))
        if FileManager.default.fileExists(atPath: fullPath.path) {
            _=callback()
            return
        }
        
        SVProgressHUD.show(withStatus: "Downloading")
        func wait() {
            if FileManager.default.fileExists(atPath: (fullPath.path)) {
                SVProgressHUD.showSuccess(withStatus: "")
                _=callback()
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                wait()
            }
        }
        wait()
    }
    
    func selectedSequence() -> JSON {
        guard let setIdx = self.selectedIdx else { return JSON(parseJSON:"[]") }
        
        let talk = model!["sets"][setIdx]["talk"]
        if talk["modes"].error == nil {
            return bookMode == .easy ? talk["modes"]["easy"] : talk["modes"]["hard"]
        }
        return talk["sequence"]
    }
    
    static func getQuoteTextOf(_ text:String, dictations:String, hideColor:String = "undefined") -> String {
        var t:String = text
        var seps:[String] = text.components(separatedBy: " ")
        let positions:[String] = dictations.components(separatedBy: ",")
        for p:String in positions {
            let idx:Int = Int(p)!
            if hideColor != "undefined" {
                seps[idx-1] = "<span style=\"color:"+hideColor+"\">"+seps[idx-1]+"</span>"
            }
            else {
                var b:String = ""
                var cnt:Int = seps[idx-1].characters.count
                while cnt > 0 {
                    b += "_"
                    cnt -= 1
                }
                seps[idx-1] = b
            }
        }
        
        t = ""
        for s:String in seps {
            t = t + s + " "
        }
        return t
    }
    
    static func shuffleWords(_ orig:String) -> String {
        var array:[String] = orig.lowercased().components(separatedBy: " ")
        
        for i in 0..<array.count-1 {
            let j = Int(arc4random_uniform(UInt32(array.count - i))) + i
            guard i != j else { continue}
            swap(&array[i], &array[j])
        }
        
        var result:String = ""
        for s in array {
            result += s + " "
        }
        
        return result.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    static func getQuoteTextOf(dialog:JSON, params:JSON, playMode:String, hideColor:String = "undefined") -> String {
        var text:String = ""
        
        if "listen" == playMode {
            return dialog["translation"].string!
        }
        else if let dictations:String = params["dictation"].string {
            text = BookController.getQuoteTextOf(dialog["text"].string!, dictations: dictations, hideColor:hideColor)
        }
        else {
            text = dialog["text"].string!
        }
        
        if params["shuffle"].stringValue == "true" {
            text = BookController.shuffleWords(text)
        }
        
        return text
    }
    
    static func getDictationTextOf(_ text:String, dictations:String) -> String {
        var t:String = ""
        var seps:[String] = text.components(separatedBy: " ")
        let positions:[String] = dictations.components(separatedBy: ",")
        for p:String in positions {
            let idx:Int = Int(p)!
            t = t + seps[idx-1] + " "
        }
        return t.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    static func getDictationResultOf(_ text:String, dictations:String, correct:Bool = true, desc:String? = nil) -> String {
        var t:String = text
        var seps:[String] = text.components(separatedBy: " ")
        let positions:[String] = dictations.components(separatedBy: ",")
        if let d:String = desc {
            for p:String in positions {
                let idx:Int = Int(p)!
                seps[idx-1] = ""
            }
            seps[Int(positions[0])! - 1] = "<u style='color:"+(correct ? "blue" : "red" )+"'>" + d + "</u>"
        } else {
            for p:String in positions {
                let idx:Int = Int(p)!
                seps[idx-1] = "<u style='color:"+(correct ? "blue" : "red" )+"'>"+seps[idx-1]+"</u>"
            }
        }
        
        t = ""
        for s:String in seps {
            guard s != "" else { continue }
            t = t + s + " "
        }
        return t
    }

    static func removeCache(_ vc:UIViewController) {
        let fullPath:URL = BookController.documentRoot()
            .appendingPathComponent("res/books")
        
        do {
            try FileManager.default.removeItem(at: fullPath)
        } catch let e as NSError {
            print(e)
        }
        
        let alertController = UIAlertController(title: "캐시 삭제", message:
            "캐시된 컨텐츠를 삭제하였습니다.", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "확인", style: UIAlertActionStyle.default,handler: nil))
        vc.present(alertController, animated: true, completion: nil)
    }
    
    static func documentRoot() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static func findBookOn(categories:JSON, bookId:String) -> JSON? {
        for cate:JSON in categories["categories"].arrayValue {
            for book:JSON in cate["books"].arrayValue {
                if book["_id"].stringValue == bookId {
                    return book
                }
            }
        }
        
        return nil
    }
    
    static func buildNoteWithPath(_ obj:JSON) -> Note {
        let bookId = obj["path"]["bookId"].stringValue
        let con:BookController = ApplicationContext.sharedInstance.sharedBookController
        con.book = Book(JSON: ["_id":bookId])!
        con.selectedIdx = obj["path"]["setIndex"].intValue
        let dialog:JSON = con.findDialogByKey(obj["path"]["key"].stringValue)!
        var thumbnail:String = ""

        if let categories:JSON = MainCont.sharedInstance().viewModel.model {
            if let bookInCategory:JSON = BookController.findBookOn(categories:categories, bookId:bookId) {
                thumbnail = bookInCategory["thumbimage"].stringValue
            }
        }
        
        let date:Date = Date(timeIntervalSince1970:(obj["registed"].doubleValue/1000))
        
        let result = Note(JSON:[
            "_id":obj["_id"].stringValue,
            "contents":dialog["text"].stringValue,
            "date":date,
            "thumbimage":thumbnail,
            "rating":obj["grade"].intValue,
            "bookId":obj["path"]["bookId"].stringValue,
            "bookTitle":con.L!["title"].stringValue,
            "voice":dialog["voice"].stringValue,
            "setIndex":con.model!["sets"][con.selectedIdx!]["index"].stringValue,
            "key":obj["path"]["key"].stringValue
        ])!

        let sequence = con.selectedSequence()
        let pivot:SituationCont.Pivot = SituationCont.Pivot.create(sequence, key: obj["path"]["key"].stringValue)
        result.backgroundImage = SituationCont.Pivot.extractThumbnail(bookId, sequence:sequence, pivot:pivot)
        result.dialog = dialog
        
        return result
    }
    
    static func coinRewardFor(_ grade:Int, basePrice:Int = 100) -> AnyObject? {
        guard grade > 0 && grade < 6 else { return 0 as AnyObject? }
        let RATE_TABLE:[Int] = [5,10,15,20,25]
        return Int((basePrice * RATE_TABLE[grade - 1]) / 100) as AnyObject?
    }
}
