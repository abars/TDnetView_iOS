//
//  AppDelegate.swift
//  tdnetview
//
//  Created by abars on 2015/04/11.
//  Copyright (c) 2015年 abars. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var mark : Mark = Mark()
    var CRON_DEBUG : Bool = false

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

        registNotification(application)
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        //sendNotification("test",url:"url")
        if(CRON_DEBUG){
            cron({new in
                print(new)
            })
        }

        let localNotification = launchOptions?[UIApplicationLaunchOptionsLocalNotificationKey] as? UILocalNotification
        if(localNotification != nil){
            notifyReceivedLocalNotification(localNotification!)
        }
        
        analyticsBegin();

        return true
    }
    
    private func analyticsBegin(){
        // Configure tracker from GoogleService-Info.plist.
        var configureError:NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        // Optional: configure GAI options.
        let gai = GAI.sharedInstance()
        gai.trackUncaughtExceptions = true  // report uncaught exceptions
        gai.logger.logLevel = GAILogLevel.Verbose  // remove before app release
    }

    func registNotification(application: UIApplication) {
        let types:UIUserNotificationType = ([.Alert, .Sound, .Badge])
        let settings:UIUserNotificationSettings = UIUserNotificationSettings(forTypes: types, categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()

        /*
        if application.respondsToSelector("registerUserNotificationSettings:") {
            if #available(iOS 8.0, *) {
                let types:UIUserNotificationType = ([.Alert, .Sound, .Badge])
                let settings:UIUserNotificationSettings = UIUserNotificationSettings(forTypes: types, categories: nil)
                application.registerUserNotificationSettings(settings)
                application.registerForRemoteNotifications()
            } else {
                application.registerForRemoteNotificationTypes([.Alert, .Sound, .Badge])
            }
        }
        else {
            // Register for Push Notifications before iOS 8
            application.registerForRemoteNotificationTypes([.Alert, .Sound, .Badge])
        }
 */
    }
    
    func sendNotification(message:String,url:String) {
        let notification = UILocalNotification()
        notification.fireDate = NSDate(timeIntervalSinceNow: 0);//0秒後
        notification.timeZone = NSTimeZone.defaultTimeZone()
        notification.alertBody = message
        notification.userInfo = ["url":url]
        notification.alertAction = "OK"
        notification.soundName = UILocalNotificationDefaultSoundName
        UIApplication.sharedApplication().scheduleLocalNotification(notification);
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        // ダウンロードなどの処理
        if(application.isRegisteredForRemoteNotifications()){
            cron({new in
                    if(new){
                        completionHandler(UIBackgroundFetchResult.NewData)
                    }else{
                        completionHandler(UIBackgroundFetchResult.NoData)
                    }
                }
            )
        }
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        /*
        var alert = UIAlertView()
        alert.title = "受け取りました"
        alert.message = notification.alertBody
        alert.addButtonWithTitle(notification.alertAction!)
        alert.show()
        */

        // アプリ起動中(フォアグラウンド)に通知が届いた場合
        if(application.applicationState == UIApplicationState.Active) {
            // ここに処理を書く
            return
        }
        
        // アプリがバックグラウンドにある状態で通知が届いた場合
        if(application.applicationState == UIApplicationState.Inactive) {
            // ここに処理を書く
        }
        
        notifyReceivedLocalNotification(notification)
    }

    func notifyReceivedLocalNotification(notification: UILocalNotification){
        print("got notification")

        if let userInfo = notification.userInfo {
            let url_str:String? = userInfo["url"] as? String
            if let tabvc = window!.rootViewController as? UITabBarController  {
                let RECENT_VIEW_INDEX:Int = 0
                tabvc.selectedIndex = RECENT_VIEW_INDEX
                let view:RecentViewController = (tabvc.viewControllers![RECENT_VIEW_INDEX] as? RecentViewController)!
                view.openPdf(url_str!)
            }else{
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    self.notifyReceivedLocalNotification(notification)
                }
            }
        }
    }

    var cron_cache:[String]=[]
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    func cron(complete_handler: (Bool) -> Void){
        let mode : Int = HttpGetTask.MODE_CRON
        
        let http_get_task:HttpGetTask = HttpGetTask(
            mode:mode,
            callback:{article in
                self.fetch_callback(article)
                var new:Bool = false
                if(article.count>=1){
                    new=article[0].new
                }
                complete_handler(new)
            }
        )
        
        if(userDefaults.objectForKey("cron") != nil){
            cron_cache = userDefaults.objectForKey("cron") as! [String]
            if(CRON_DEBUG){
                cron_cache=[]
            }
        }
        
        var cache:[Article] = []
        if(cron_cache.count>=1){
            let art:Article = Article()
            art.cache=cron_cache[0]
            cache.append(art)
        }
        
        http_get_task.setCacheCron(cache)
        if(CRON_DEBUG){
            http_get_task.getData("recent",page:0,page_unit:10)
        }else{
            http_get_task.getData("",page:0,page_unit:0)
        }
    }
    
    func fetch_callback(new_item:[Article]){
        var new_cache:[String] = []
        
        for item in new_item{
            new_cache.append(item.cache)  //最初の一つは必ず登録
             if(cron_cache.count>=1){
                if(cron_cache[0]==item.cache){
                    continue
                }
            }

            if(CRON_DEBUG || mark.is_mark(item.code)){
                print(item.cell)
                sendNotification(item.cell,url:item.url)
            }
        }
 
        userDefaults.setObject(new_cache, forKey: "cron")
        userDefaults.synchronize()
    }
}

