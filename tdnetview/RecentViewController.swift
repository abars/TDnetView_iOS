//
//  RecentViewController.swift
//  tdnetview
//
//  Created by abars on 2015/04/11.
//  Copyright (c) 2015年 abars. All rights reserved.
//

import UIKit
import Social
import SafariServices

class RecentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate , SFSafariViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var http_get_task : HttpGetTask!
    var mark : Mark!
    var search_query: String = ""
    var first_load : Bool = true
    var dark_mode : Bool = false;
    var dark_mode_font_color : UIColor = UIColor.whiteColor()
    var dark_mode_font_color_css : String = ""
    
    var page : Int = 0
    let PAGE_UNIT : Int = 50
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        
        var mode:Int = HttpGetTask.MODE_RECENT
        if(self.isSearchScreen()){
            mode=HttpGetTask.MODE_SEARCH
        }
        if(self.isMarkScreen()){
            mode=HttpGetTask.MODE_MARK
        }

        let myAp = UIApplication.sharedApplication().delegate as! AppDelegate
        dark_mode=myAp.isDarkMode();
        dark_mode_font_color=myAp.DarkModeFontColor()
        dark_mode_font_color_css=myAp.DarkModeFontColorCss()
        http_get_task = HttpGetTask(mode:mode,dark_mode:dark_mode,dark_mode_font_color_css:dark_mode_font_color_css,callback:self.fetchCallback)
        
        self.mark = myAp.mark
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.rowHeight = UITableViewAutomaticDimension

        if(!isSearchScreen()){
            refreshControl.addTarget(self, action: #selector(RecentViewController.refresh), forControlEvents: UIControlEvents.ValueChanged)
            self.tableView.addSubview(refreshControl)
        }
        
        registMenuNormal()
        self.tableView.registerClass(CustomTableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func viewDidAppear(animated:Bool) {
        super.viewDidAppear(animated)
        if(!isSearchScreen()){
            if(first_load){
                if(!isMarkScreen()){
                    let cache:[Article]=http_get_task.getArticleCache();
                    if(cache.count >= 1){
                        updateTable(cache)
                        first_load=false;
                    }
                }
                if(first_load){
                    showMessage("読込中...")
                    refresh()
                }
                first_load=false;
            }
        }
        if(mark.is_updated()){
            updateTable(self.texts)
        }
        self.registMenuNormal()
        
        analyticsTrack();
    }
    
    private func analyticsTrack(){
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: getTabName())
        
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject : AnyObject])
    }
    
    private func getTabName() -> String{
        if(isSearchScreen()){
            return "search"
        }
        if(isMarkScreen()){
            return "favorite"
        }
        return "recent"
    }
    
    func showMessage(message:String){
        let art:Article = Article()
        art.cell=message
        art.url=""
        
        var new_texts : [Article] = []
        new_texts.append(art)
        
        updateTable(new_texts)
    }

    func registMenuNormal(){
        //self.canDisplayBannerAds = false

        let menuItem: UIMenuItem = UIMenuItem(title: "Favorite", action: #selector(RecentViewController.mark(_:)))
        let menuItem2: UIMenuItem = UIMenuItem(title: "Tweet", action: #selector(RecentViewController.tweet(_:)))
        let menuItem3: UIMenuItem = UIMenuItem(title: "Yahoo", action: #selector(RecentViewController.yahoo(_:)))
        let menuItem4: UIMenuItem = UIMenuItem(title: "Search", action: #selector(RecentViewController.search(_:)))
        UIMenuController.sharedMenuController().menuItems = [menuItem, menuItem2, menuItem3, menuItem4]
        UIMenuController.sharedMenuController().update()
    }
    
    func registMenuMark(){
        //self.canDisplayBannerAds = false
        
        let menuItem: UIMenuItem = UIMenuItem(title: "Remove", action: #selector(RecentViewController.mark(_:)))
        let menuItem2: UIMenuItem = UIMenuItem(title: "Tweet", action: #selector(RecentViewController.tweet(_:)))
        let menuItem3: UIMenuItem = UIMenuItem(title: "Yahoo", action: #selector(RecentViewController.yahoo(_:)))
        let menuItem4: UIMenuItem = UIMenuItem(title: "Search", action: #selector(RecentViewController.search(_:)))
        UIMenuController.sharedMenuController().menuItems = [menuItem, menuItem2, menuItem3, menuItem4]
        UIMenuController.sharedMenuController().update()
    }

    func registMenuList(){
        //self.canDisplayBannerAds = true

        let menuItem: UIMenuItem = UIMenuItem(title: "Remove", action: #selector(RecentViewController.remove(_:)))
        UIMenuController.sharedMenuController().menuItems = [menuItem]
        UIMenuController.sharedMenuController().update()
    }

    func fetchCallback(new_item:[Article]){
        var new_texts:[Article]=[]
        
        let add_pager:Bool = new_item.count>=PAGE_UNIT/2 && (isMarkScreen() || isSearchScreen())
        
        //if(add_pager &&
        if(page>=1){
            let prev:Article = Article()
            prev.cell="Prev"
            prev.url="prev"
            new_texts.insert(prev,atIndex:0)
        }
        
        new_texts.appendContentsOf(new_item)
        
        if(add_pager){
            let next:Article = Article()
            next.cell="Next"
            next.url="next"
            new_texts.append(next)
        }
        
        self.updateTable(new_texts)
    }
    
    func isSearchScreen() -> Bool{
        return false;
    }
    
    func isMarkScreen() -> Bool{
        return false;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // セルに表示するテキスト
    var texts:[Article] = []
    
    var refreshControl : UIRefreshControl = UIRefreshControl();
    var refreshing : Bool = false
    
    func clear() {
        self.updateTable([])
    }

    func refresh() {
        if(refreshing){
            return
        }
        
        refreshing=true

        var query:String=""
        if(isMarkScreen()){
            query=mark.get_query()
            print(query)
        }
        if(isSearchScreen()){
            query=self.search_query
        }
        //self.refreshControl.beginRefreshing()
        http_get_task.getData(query,page:page,page_unit:PAGE_UNIT);
    }

    func clearTable(){
        dispatch_async(dispatch_get_main_queue(), {
            self.updateTable([])
        });
    }
    
    func updateBudge(new_texts:[Article]) -> [Article]{
        if(!(isSearchScreen() || isMarkScreen())){
            var mark_text:[Article]=[];
            var no_mark_text:[Article]=[];

            var cnt:Int=0
            for text in new_texts {
                if(text.new && mark.is_mark(text.code)){
                    cnt += 1
                    mark_text.append(text);
                }else{
                    no_mark_text.append(text);
                }
            }
            if(cnt>=1){
                self.tabBarItem.badgeValue = String(cnt)
            }else{
                self.tabBarItem.badgeValue=nil
            }
            
            mark_text.appendContentsOf(no_mark_text);
            return mark_text;
        }
        return new_texts
    }

    func updateTable(new_texts:[Article]){
        self.refreshControl.endRefreshing()
        
        var sort_texts:[Article]=updateBudge(new_texts);

        dispatch_async(dispatch_get_main_queue(), {
            self.texts=sort_texts
            self.tableView.reloadData()
        });
        
        refreshing=false
    }
    
    //セルの内容を変更
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: CustomTableViewCell = CustomTableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        
        var now:Article = Article()
        if(indexPath.row<self.texts.count){
            now=self.texts[indexPath.row]
        }
        
        cell.idx=indexPath.row
        let url:String=now.url
        if(url=="next" || url=="prev"){
            cell.util=true
        }
        cell.view=self
        
        if(dark_mode){
            cell.textLabel?.textColor=dark_mode_font_color;
        }
        
        if(isSearchScreen()){
            if(now.attribute != nil){
                cell.textLabel?.attributedText=now.attribute!
            }else{
                cell.textLabel?.text=now.cell
            }
        }else{
            cell.textLabel?.text = now.cell
        }
        
        if(mark.is_mark(now.code) && !isMarkScreen()){
            cell.backgroundColor=UIColor(red:95/255.0 , green:199/255.0 , blue:248/255.0 , alpha:1.0)
        }else{
            if(now.new && !isSearchScreen() && !isMarkScreen()){
                cell.backgroundColor=UIColor(red:240/255.0 , green:240/255.0 , blue:240/255.0 , alpha:1.0)
            }else{
                cell.backgroundColor=UIColor.clearColor()
            }
        }
        
        cell.textLabel?.numberOfLines=0
        
        cell.sizeToFit()
        
        return cell
    }

    func tableView(tableView: UITableView,heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension;
    }

    func tableView(tableView: UITableView,estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension;
    }
   
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return texts.count
    }

    func tableView(table: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        let url_str:String = self.texts[indexPath.row].url
        if(url_str==""){
            return
        }
        if(url_str=="prev"){
            page=page-1
            clear()
            refresh()
            return
        }
        if(url_str=="next"){
            page=page+1
            clear()
            refresh()
            return
        }
        openPdf(url_str)
    }
    
    var svc :SFSafariViewController? = nil
    
    func openPdf(url_str:String){
        let url = NSURL(string: url_str)
        if(url==nil){
            return
        }
        
        if(svc != nil){
            svc!.dismissViewControllerAnimated(false, completion: nil)
            svc = nil
        }

        svc = SFSafariViewController(URL: url!)
        self.presentViewController(svc!, animated: true, completion: nil)        
    }

    func safariViewControllerDidFinish(controller: SFSafariViewController)
    {
        controller.dismissViewControllerAnimated(true, completion: nil)
        svc = nil
    }
    
    // ★ 以下UIMenuControllerをカスタマイズするのに必要
    func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    }
    
    func tweet(idx:Int){
        let text = self.texts[idx].tweet
        if(text==""){
            return
        }
    
        let composeViewController: SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)!
        composeViewController.setInitialText(text)
    
        self.presentViewController(composeViewController, animated: true, completion: nil)
    }
    
    func mark(idx:Int){
        let text = self.texts[idx].code
        if(text==""){
            return
        }
        
        self.mark.add_remove(text)
        updateTable(self.texts)
        
        if(isMarkScreen()){
            refresh()   //deleteをケア
        }
    }

    func yahoo(idx:Int){
        var company : String = self.texts[idx].code
        if(company==""){
            return
        }
        company = (company as NSString).substringToIndex(4)

        let text : String
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad{
            text="http://stocks.finance.yahoo.co.jp/stocks/detail/?code="+company+"&d=1y";
        }else{
            text="http://m.finance.yahoo.co.jp/stock?code="+company;
        }

        let url_str:String = text
        let url = NSURL(string: url_str)
        if UIApplication.sharedApplication().canOpenURL(url!){
            UIApplication.sharedApplication().openURL(url!)
        }
    }
    
    func remove(idx:Int){
    }

    func search(idx:Int){
        let company : String = self.texts[idx].code
        print(company)
        if(company==""){
            return
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            let myAp = UIApplication.sharedApplication().delegate as! AppDelegate
            if let tabvc = myAp.window!.rootViewController as? UITabBarController  {
                let SEARCH_VIEW_INDEX:Int = 2
                tabvc.selectedIndex = SEARCH_VIEW_INDEX
                let view:SearchViewController = (tabvc.viewControllers![SEARCH_VIEW_INDEX] as? SearchViewController)!
                view.searchRequest("code:"+company)
            }
        })
    }
}

