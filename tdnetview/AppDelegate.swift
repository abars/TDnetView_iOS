//
//  AppDelegate.swift
//  tdnetview
//
//  Created by abars on 2015/04/11.
//  Copyright (c) 2015年 abars. All rights reserved.
//

import UIKit

extension UIApplication {
    class var statusBarBackgroundColor: UIColor? {
        get {
            return (shared.value(forKey: "statusBar") as? UIView)?.backgroundColor
        } set {
            (shared.value(forKey: "statusBar") as? UIView)?.backgroundColor = newValue
        }
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var mark : Mark = Mark()
    var CRON_DEBUG : Bool = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        registNotification(application)
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        //sendNotification("test",url:"url")
        if(CRON_DEBUG){
            cron({new in
                print(new)
            })
        }

        let localNotification = launchOptions?[UIApplication.LaunchOptionsKey.localNotification] as? UILocalNotification
        if(localNotification != nil){
            notifyReceivedLocalNotification(localNotification!)
        }
        
        analyticsBegin();

        if(isDarkMode()){
            DarkMode();
        }
        
        return true
    }
    
    func isDarkMode() -> Bool{
        let userDefaults = UserDefaults.standard
        if(userDefaults.object(forKey: "dark_mode") != nil){
            let dark_mode:Bool = (userDefaults.object(forKey: "dark_mode")! as AnyObject).boolValue
            return dark_mode;
        }
        return false;
    }

    fileprivate func DarkMode(){
        let r:CGFloat = 32
        let bg_color:UIColor=UIColor(red: r/255, green: r/255, blue: r/255, alpha: 1.0)
        
        let font_color:UIColor=DarkModeFontColor();
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        UIApplication.statusBarBackgroundColor = bg_color;
        
        UITabBar.appearance().backgroundColor = bg_color
        UITabBar.appearance().barTintColor = bg_color
        UITabBar.appearance().tintColor = UIColor(red: 24*4/255, green: 31*4/255, blue: 71*4/255, alpha: 1.0)
        
        UITableView.appearance().backgroundColor = bg_color
        UITableView.appearance().tintColor = font_color

        UISearchBar.appearance().backgroundColor = bg_color
        UISearchBar.appearance().barTintColor = bg_color
        UISearchBar.appearance().tintColor = font_color

        UITextField.appearance().backgroundColor = font_color
        UITextField.appearance().tintColor = font_color
    }
    
    func DarkModeFontColor() -> UIColor{
        let r2:CGFloat = 224
        let font_color:UIColor=UIColor(red: r2/255, green: r2/255, blue: r2/255, alpha: 1.0)
        return font_color
    }
    
    func DarkModeFontColorCss() -> String{
        return "color:#e0e0e0";
    }

    fileprivate func analyticsBegin(){
        // Configure tracker from GoogleService-Info.plist.
        var configureError:NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        // Optional: configure GAI options.
        let gai = GAI.sharedInstance()
        gai?.trackUncaughtExceptions = true  // report uncaught exceptions
        gai?.logger.logLevel = GAILogLevel.verbose  // remove before app release
    }

    func registNotification(_ application: UIApplication) {
        let types:UIUserNotificationType = ([.alert, .sound, .badge])
        let settings:UIUserNotificationSettings = UIUserNotificationSettings(types: types, categories: nil)
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
    
    func sendNotification(_ message:String,url:String) {
        let notification = UILocalNotification()
        notification.fireDate = Date(timeIntervalSinceNow: 0);//0秒後
        notification.timeZone = TimeZone.current
        notification.alertBody = message
        notification.userInfo = ["url":url]
        notification.alertAction = "OK"
        notification.soundName = UILocalNotificationDefaultSoundName
        UIApplication.shared.scheduleLocalNotification(notification);
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // ダウンロードなどの処理
        if(application.isRegisteredForRemoteNotifications){
            cron({new in
                    if(new){
                        completionHandler(UIBackgroundFetchResult.newData)
                    }else{
                        completionHandler(UIBackgroundFetchResult.noData)
                    }
                }
            )
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        /*
        var alert = UIAlertView()
        alert.title = "受け取りました"
        alert.message = notification.alertBody
        alert.addButtonWithTitle(notification.alertAction!)
        alert.show()
        */

        // アプリ起動中(フォアグラウンド)に通知が届いた場合
        if(application.applicationState == UIApplication.State.active) {
            // ここに処理を書く
            return
        }
        
        // アプリがバックグラウンドにある状態で通知が届いた場合
        if(application.applicationState == UIApplication.State.inactive) {
            // ここに処理を書く
        }
        
        notifyReceivedLocalNotification(notification)
    }

    func notifyReceivedLocalNotification(_ notification: UILocalNotification){
        print("got notification")

        if let userInfo = notification.userInfo {
            let url_str:String? = userInfo["url"] as? String
            if let tabvc = window!.rootViewController as? UITabBarController  {
                tabvc.selectedIndex = RECENT_VIEW_INDEX
                let view:RecentViewController = (tabvc.viewControllers![RECENT_VIEW_INDEX] as? RecentViewController)!
                view.openPdf(url_str!)
            }else{
                let delayTime = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: delayTime) {
                    self.notifyReceivedLocalNotification(notification)
                }
            }
        }
    }
    
    let RECENT_VIEW_INDEX:Int = 0
    let MARK_VIEW_INDEX:Int = 1
    let SEARCH_VIEW_INDEX:Int = 2

    func searchScreenSelected(){
        if let tabvc = window!.rootViewController as? UITabBarController  {
            tabvc.selectedIndex = SEARCH_VIEW_INDEX
            let view:SearchViewController = (tabvc.viewControllers![SEARCH_VIEW_INDEX] as? SearchViewController)!
            view.backToTop();
        }
    }
    
    func recentScreenSelected(){
        if let tabvc = window!.rootViewController as? UITabBarController  {
            tabvc.selectedIndex = RECENT_VIEW_INDEX
            let view:RecentViewController = (tabvc.viewControllers![RECENT_VIEW_INDEX] as? RecentViewController)!
            view.listToTop();
        }
    }

    func markScreenSelected(){
        if let tabvc = window!.rootViewController as? UITabBarController  {
            tabvc.selectedIndex = MARK_VIEW_INDEX
            let view:MarkViewController = (tabvc.viewControllers![MARK_VIEW_INDEX] as? MarkViewController)!
            view.listToTop();
        }
    }

    var cron_cache:[String]=[]
    
    func cron(_ complete_handler: @escaping (Bool) -> Void){
        let mode : Int = HttpGetTask.MODE_CRON
        
        let http_get_task:HttpGetTask = HttpGetTask(
            mode:mode,
            dark_mode:false,
            dark_mode_font_color_css:"",
            callback:{article in
                self.fetch_callback(article)
                var new_flag:Bool = false
                if(article.count>=1){
                    new_flag=article[0].new
                }
                complete_handler(new_flag)
            }
        )
        
        let userDefaults = UserDefaults.standard
        if(userDefaults.object(forKey: "cron") != nil){
            cron_cache = userDefaults.object(forKey: "cron") as! [String]
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
    
    func fetch_callback(_ new_item:[Article]){
        var new_cache:[String] = []
        
        //Server Error
        if(new_item.count==0){
            return
        }
        if(new_item[0].cache==""){
            return
        }

        //Call
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

        let userDefaults = UserDefaults.standard
        userDefaults.set(new_cache, forKey: "cron")
        userDefaults.synchronize()
    }
}

