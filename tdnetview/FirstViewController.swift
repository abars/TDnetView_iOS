//
//  FirstViewController.swift
//  tdnetview
//
//  Created by abars on 2015/04/11.
//  Copyright (c) 2015年 abars. All rights reserved.
//

import UIKit
import Social

class FirstViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    @IBOutlet weak var tableView: UITableView!
    
    var http_get_task : HttpGetTask!
    var mark : Mark!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        http_get_task = HttpGetTask(self)
        
        var myAp = UIApplication.sharedApplication().delegate as! AppDelegate
        self.mark = myAp.mark
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.rowHeight = UITableViewAutomaticDimension

        if(!isSearchScreen()){
            //refreshControl = UIRefreshControl()
            //self.refreshControl.attributedTitle = NSAttributedString(string: "引っ張って更新")
            refreshControl.addTarget(self, action: Selector("refresh"), forControlEvents: UIControlEvents.ValueChanged)
            //self.refreshControl = refreshControl
            self.tableView.addSubview(refreshControl)
        }
        
        var menuItem: UIMenuItem = UIMenuItem(title: "Favorite", action: "mark:")
        var menuItem2: UIMenuItem = UIMenuItem(title: "Tweet", action: "tweet:")
        var menuItem3: UIMenuItem = UIMenuItem(title: "Yahoo", action: "yahoo:")
        UIMenuController.sharedMenuController().menuItems = [menuItem, menuItem2, menuItem3]
        UIMenuController.sharedMenuController().update()
        self.tableView.registerClass(CustomTableViewCell.self, forCellReuseIdentifier: "Cell")
        
        if(!isSearchScreen()){
            refresh()
        }
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

    func refresh() {
        var query:String=""
        if(isMarkScreen()){
            query=mark.get_query()
            print(query)
        }
        http_get_task.getData(query);
    }
    

    func updateTable(){
        if(!(isSearchScreen() || isMarkScreen())){
        var cnt:Int=0
        for text in self.texts {
            if(mark.is_mark(text.code)){
                cnt++
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
    }
    
    //セルの内容を変更
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: CustomTableViewCell = CustomTableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        
        cell.idx=indexPath.row
        cell.view=self;
        
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
            cell.backgroundColor=UIColor(red:137/255.0 , green:195/255.0 , blue:235/255.0 , alpha:1.0)
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
        var url_str:String = self.texts[indexPath.row].url
        let url = NSURL(string: url_str)
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
    
    func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject!) {
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

        var text : String = "http://m.finance.yahoo.co.jp/stock?code="+company;

        var url_str:String = text
        let url = NSURL(string: url_str)
        if UIApplication.sharedApplication().canOpenURL(url!){
            UIApplication.sharedApplication().openURL(url!)
        }
    }

}

