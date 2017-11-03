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
    var dark_mode_font_color : UIColor = UIColor.white
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

        let myAp = UIApplication.shared.delegate as! AppDelegate
        dark_mode=myAp.isDarkMode();
        dark_mode_font_color=myAp.DarkModeFontColor()
        dark_mode_font_color_css=myAp.DarkModeFontColorCss()
        http_get_task = HttpGetTask(mode:mode,dark_mode:dark_mode,dark_mode_font_color_css:dark_mode_font_color_css,callback:self.fetchCallback)
        
        self.mark = myAp.mark
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.rowHeight = UITableViewAutomaticDimension

        if(!isSearchScreen()){
            refreshControl.addTarget(self, action: #selector(RecentViewController.refresh), for: UIControlEvents.valueChanged)
            self.tableView.addSubview(refreshControl)
        }
        
        registMenuNormal()
        self.tableView.register(CustomTableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func viewDidAppear(_ animated:Bool) {
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
    
    fileprivate func analyticsTrack(){
        let tracker = GAI.sharedInstance().defaultTracker
        tracker?.set(kGAIScreenName, value: getTabName())
        
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker?.send(builder?.build() as! [AnyHashable: Any])
    }
    
    fileprivate func getTabName() -> String{
        if(isSearchScreen()){
            return "search"
        }
        if(isMarkScreen()){
            return "favorite"
        }
        return "recent"
    }
    
    func showMessage(_ message:String){
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
        UIMenuController.shared.menuItems = [menuItem, menuItem2, menuItem3, menuItem4]
        UIMenuController.shared.update()
    }
    
    func registMenuMark(){
        //self.canDisplayBannerAds = false
        
        let menuItem: UIMenuItem = UIMenuItem(title: "Remove", action: #selector(RecentViewController.mark(_:)))
        let menuItem2: UIMenuItem = UIMenuItem(title: "Tweet", action: #selector(RecentViewController.tweet(_:)))
        let menuItem3: UIMenuItem = UIMenuItem(title: "Yahoo", action: #selector(RecentViewController.yahoo(_:)))
        let menuItem4: UIMenuItem = UIMenuItem(title: "Search", action: #selector(RecentViewController.search(_:)))
        UIMenuController.shared.menuItems = [menuItem, menuItem2, menuItem3, menuItem4]
        UIMenuController.shared.update()
    }

    func registMenuList(){
        //self.canDisplayBannerAds = true

        let menuItem: UIMenuItem = UIMenuItem(title: "Remove", action: #selector(RecentViewController.remove(_:)))
        UIMenuController.shared.menuItems = [menuItem]
        UIMenuController.shared.update()
    }

    func fetchCallback(_ new_item:[Article]){
        var new_texts:[Article]=[]
        
        let add_pager:Bool = new_item.count>=PAGE_UNIT/2 && (isMarkScreen() || isSearchScreen())
        
        //if(add_pager &&
        if(page>=1){
            let prev:Article = Article()
            prev.cell="Prev"
            prev.url="prev"
            new_texts.insert(prev,at:0)
        }
        
        new_texts.append(contentsOf: new_item)
        
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
        DispatchQueue.main.async(execute: {
            self.updateTable([])
        });
    }
    
    func updateBudge(_ new_texts:[Article]) -> [Article]{
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
            
            mark_text.append(contentsOf: no_mark_text);
            return mark_text;
        }
        return new_texts
    }

    func updateTable(_ new_texts:[Article]){
        self.refreshControl.endRefreshing()
        
        let sort_texts:[Article]=updateBudge(new_texts);

        DispatchQueue.main.async(execute: {
            self.texts=sort_texts
            self.tableView.reloadData()
        });
        
        refreshing=false
    }
    
    //セルの内容を変更
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: CustomTableViewCell = CustomTableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "Cell")
        
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
            
            let cellSelectedBgView = UIView()
            cellSelectedBgView.backgroundColor = UIColor.black
            cell.selectedBackgroundView=cellSelectedBgView
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
        
        var dark:CGFloat=1.0;
        var dark_new:CGFloat=1.0;
        if(dark_mode){
            dark=0.4;
            dark_new=0.2;
        }
        
        if(mark.is_mark(now.code) && !isMarkScreen()){
            cell.backgroundColor=UIColor(red:95/255.0*dark , green:199/255.0*dark , blue:248/255.0*dark , alpha:1.0)
        }else{
            if(now.new && !isSearchScreen() && !isMarkScreen()){
                cell.backgroundColor=UIColor(red:240/255.0*dark_new , green:240/255.0*dark_new , blue:240/255.0*dark_new , alpha:1.0)
            }else{
                cell.backgroundColor=UIColor.clear
            }
        }
        
        cell.textLabel?.numberOfLines=0
        
        cell.sizeToFit()
        
        return cell
    }

    func tableView(_ tableView: UITableView,heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension;
    }

    func tableView(_ tableView: UITableView,estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension;
    }
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return texts.count
    }

    func tableView(_ table: UITableView, didSelectRowAt indexPath:IndexPath) {
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
    
    func openPdf(_ url_str:String){
        let url = URL(string: url_str)
        if(url==nil){
            return
        }
        
        if(svc != nil){
            svc!.dismiss(animated: false, completion: nil)
            svc = nil
        }

        svc = SFSafariViewController(url: url!)
        self.present(svc!, animated: true, completion: nil)        
    }

    func safariViewControllerDidFinish(_ controller: SFSafariViewController)
    {
        controller.dismiss(animated: true, completion: nil)
        svc = nil
    }
    
    // ★ 以下UIMenuControllerをカスタマイズするのに必要
    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
    }
    
    func tweet(_ idx:Int){
        let text = self.texts[idx].tweet
        if(text==""){
            return
        }
    
        let composeViewController: SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)!
        composeViewController.setInitialText(text)
    
        self.present(composeViewController, animated: true, completion: nil)
    }
    
    func mark(_ idx:Int){
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

    func yahoo(_ idx:Int){
        var company : String = self.texts[idx].code
        if(company==""){
            return
        }
        company = (company as NSString).substring(to: 4)

        let text : String
        if UIDevice.current.userInterfaceIdiom == .pad{
            text="http://stocks.finance.yahoo.co.jp/stocks/detail/?code="+company+"&d=1y";
        }else{
            text="http://m.finance.yahoo.co.jp/stock?code="+company;
        }

        let url_str:String = text
        let url = URL(string: url_str)
        if UIApplication.shared.canOpenURL(url!){
            UIApplication.shared.openURL(url!)
        }
    }
    
    func remove(_ idx:Int){
    }

    func search(_ idx:Int){
        let company : String = self.texts[idx].code
        print(company)
        if(company==""){
            return
        }
        
        DispatchQueue.main.async(execute: {
            let myAp = UIApplication.shared.delegate as! AppDelegate
            if let tabvc = myAp.window!.rootViewController as? UITabBarController  {
                let SEARCH_VIEW_INDEX:Int = 2
                tabvc.selectedIndex = SEARCH_VIEW_INDEX
                let view:SearchViewController = (tabvc.viewControllers![SEARCH_VIEW_INDEX] as? SearchViewController)!
                view.searchRequest("code:"+company)
            }
        })
    }
    
    func listToTop(){
        let lastPath:IndexPath = IndexPath(row:0, section:0)
        tableView.scrollToRow( at: lastPath , at: .top, animated: true)
    }
}

