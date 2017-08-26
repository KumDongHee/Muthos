//
//  AppDelegate.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 15..
//
//

import UIKit
import CoreData
import MMDrawerController
import SwiftyJSON
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var drawerController: MMDrawerController!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        _ = ApplicationContext.sharedInstance
        
        if ApiProvider.isLogin() {
            goMain()
        } else {
            goLogin()
        }
        
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        ApplicationContext.sharedInstance.pause()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
        
        ApplicationContext.sharedInstance.resume()
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        //self.saveContext()
    }
    
    // MARK: - Core Data stack
    /*
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "net.muthos.muthos" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "muthos", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    */
    // MARK: - Navigation
    func goMain() {
        let navCont = UINavigationController(rootViewController: MainCont.sharedInstance())
        
        drawerController = MMDrawerController(center: navCont, leftDrawerViewController: MenuCont.sharedInstance())
        drawerController.maximumLeftDrawerWidth = MENU_WIDTH
        drawerController.closeDrawerGestureModeMask = .all
        drawerController.shouldStretchDrawer = false
        drawerController.setDrawerVisualStateBlock {(controller:MMDrawerController?, side:MMDrawerSide, percent:CGFloat) -> Void in
            if percent == 0 {
                //menu 닫혔을 때 status bar 원복
            } else if percent == 1 {
                //열렸을 때 흰색으로 표시
            }
        }
        
        window?.rootViewController = self.drawerController
        let cont = MainCont.sharedInstance()
        cont.perform(#selector(MainCont.reloadData), with: nil, afterDelay: 0.1)
    }
    
    func goLogin() {
        let storyboard = UIStoryboard(name: "Account", bundle: nil)
        let loginCont = storyboard.instantiateViewController(withIdentifier: "LoginCont")
        let navCont = UINavigationController(rootViewController: loginCont)
        
        window?.rootViewController = navCont
    }
    
    func doTestShining(_ mainCont:MainCont) {
//        TC_producer.perform(for: "dictation")
    }
    
    func doTestShiningRoulette(_ mainCont:MainCont) {
        let sm:SetMainCont = mainCont.navigationController!.topViewController as! SetMainCont
        sm.showRoulette()
    }
    
    func doTestSjkim(_ mainCont:MainCont) {
        let book:Book = Book(JSON: ["_id":"20160308-01", "name": "In the city", "thumbimage": "01_01"])!
        book.sets = [BookSet(JSON: ["index":1, "title":"Leaving from anything else", "coverImage":"source_bg_login", "rating":2.0])!]
        
        //        mainCont.selectBook(book)
        let sm:SetMainCont = mainCont.navigationController!.topViewController as! SetMainCont
        sm.showTalk()
        
        self.perform(#selector(AppDelegate.doTestSjkim001(_:)), with: mainCont, afterDelay: 0.5)
    }
    
    
    func doTestSjkim001(_ mainCont:MainCont) {
        let sc:SituationCont = mainCont.navigationController!.topViewController as! SituationCont
        sc.doTest()
    }
}

