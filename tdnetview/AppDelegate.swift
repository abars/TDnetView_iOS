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

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

        registNotification(application)
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        //sendNotification("test",url:"url")
        //cron({})
        
        return true
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
        notification.fireDate = NSDate(timeIntervalSinceNow: 1);//1秒後
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
            cron({
                    completionHandler(UIBackgroundFetchResult.NewData)
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
        
        print("got notification")
        
        if let userInfo = notification.userInfo {
            let url_str:String? = userInfo["url"] as? String
            let url = NSURL(string: url_str!)
            print(url)
            if UIApplication.sharedApplication().canOpenURL(url!){
                UIApplication.sharedApplication().openURL(url!)
            }
        }
    }

    var cron_cache:[String]=[]
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    func cron(complete_handler: () -> Void){
        let http_get_task:HttpGetTask = HttpGetTask(
            mode:HttpGetTask.MODE_CRON,
            callback:{article in
                self.fetch_callback(article)
                complete_handler()
            }
        )
        
        if(userDefaults.objectForKey("cron") != nil){
            cron_cache = userDefaults.objectForKey("cron") as! [String]
        }
        
        var cache:[Article] = []
        if(cron_cache.count>=1){
            let art:Article = Article()
            art.cache=cron_cache[0]
            cache.append(art)
        }
        
        http_get_task.setCacheCron(cache)
        http_get_task.getData("",page:0,page_unit:0)
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

            if(mark.is_mark(item.code)){
                print(item.cell)
                sendNotification(item.cell,url:item.url)
            }
        }
 
        userDefaults.setObject(new_cache, forKey: "cron")
        userDefaults.synchronize()
    }
}

