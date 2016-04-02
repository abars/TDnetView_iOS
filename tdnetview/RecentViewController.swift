//
//  RecentViewController.swift
//  tdnetview
//
//  Created by abars on 2015/04/11.
//  Copyright (c) 2015年 abars. All rights reserved.
//

import UIKit
import Social
import iAd

class RecentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    @IBOutlet weak var tableView: UITableView!
    
    var http_get_task : HttpGetTask!
    var mark : Mark!
    var search_query: String = ""
    
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
        http_get_task = HttpGetTask(mode:mode,callback:self.fetchCallback)
        
        let myAp = UIApplication.sharedApplication().delegate as! AppDelegate
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

        if(!isSearchScreen()){
            refresh()
        }
    }
    
    override func viewDidAppear(animated:Bool) {
        super.viewDidAppear(animated)
        if(mark.is_updated()){
            updateTable()
        }
    }

    func registMenuNormal(){
        self.canDisplayBannerAds = false

        let menuItem: UIMenuItem = UIMenuItem(title: "Favorite", action: #selector(RecentViewController.mark(_:)))
        let menuItem2: UIMenuItem = UIMenuItem(title: "Tweet", action: #selector(RecentViewController.tweet(_:)))
        let menuItem3: UIMenuItem = UIMenuItem(title: "Yahoo", action: #selector(RecentViewController.yahoo(_:)))
        let menuItem4: UIMenuItem = UIMenuItem(title: "Search", action: #selector(RecentViewController.search(_:)))
        UIMenuController.sharedMenuController().menuItems = [menuItem, menuItem2, menuItem3, menuItem4]
        UIMenuController.sharedMenuController().update()
    }

    func registMenuList(){
        self.canDisplayBannerAds = true

        let menuItem: UIMenuItem = UIMenuItem(title: "Remove", action: #selector(RecentViewController.remove(_:)))
        UIMenuController.sharedMenuController().menuItems = [menuItem]
        UIMenuController.sharedMenuController().update()
    }

    func fetchCallback(new_item:[Article]){
        self.texts=[]
        
        let add_pager:Bool = new_item.count>=PAGE_UNIT/2 && (isMarkScreen() || isSearchScreen())
        
        if(add_pager && page>=1){
            let prev:Article = Article()
            prev.cell="Prev"
            prev.url="prev"
            self.texts.insert(prev,atIndex:0)
        }
        
        self.texts.appendContentsOf(new_item)
        
        if(add_pager){
            let next:Article = Article()
            next.cell="Next"
            next.url="next"
            self.texts.append(next)
        }
        
        self.updateTable()
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
        self.texts=[]
        self.updateTable()
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
        self.refreshControl.beginRefreshing()
        http_get_task.getData(query,page:page,page_unit:PAGE_UNIT);
    }
    

    func updateTable(){
        if(!(isSearchScreen() || isMarkScreen())){
        var cnt:Int=0
        for text in self.texts {
            if(mark.is_mark(text.code)){
                cnt += 1
            }
        }
        if(cnt>=1){
            //self.tabBarItem.badgeValue = String(cnt)
        }else{
            self.tabBarItem.badgeValue=nil
        }
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        });
        self.refreshControl.endRefreshing()
        
        refreshing=false
    }
    
    //セルの内容を変更
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: CustomTableViewCell = CustomTableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        
        cell.idx=indexPath.row
        var url:String=texts[indexPath.row].url
        if(url=="next" || url=="prev"){
            cell.util=true
        }
        cell.view=self
        
        if(isSearchScreen()){
            let cell_text:String = texts[indexPath.row].cell
            let string:String = "<style>body{font-size:16px;}</style>"+cell_text
        
            let encodedData = string.dataUsingEncoding(NSUTF8StringEncoding)!
            let attributedOptions : [String: AnyObject] = [
                NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
            ]
        
            var attributedString:NSAttributedString?
        
            do{
                attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
            }catch{
                print(error)
            }
        
            cell.textLabel?.attributedText = attributedString!
        }else{
            cell.textLabel?.text = texts[indexPath.row].cell
        }
        
        if(mark.is_mark(texts[indexPath.row].code) && !isMarkScreen()){
            cell.backgroundColor=UIColor(red:95/255.0 , green:199/255.0 , blue:248/255.0 , alpha:1.0)
        }else{
            cell.backgroundColor=UIColor.clearColor()
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
        let url = NSURL(string: url_str)
        if(url==nil){
            return
        }
        if UIApplication.sharedApplication().canOpenURL(url!){
            UIApplication.sharedApplication().openURL(url!)
        }
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
        updateTable()
        
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

        let text : String = "http://m.finance.yahoo.co.jp/stock?code="+company;

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

