//
//  FirstViewController.swift
//  tdnetview
//
//  Created by abars on 2015/04/11.
//  Copyright (c) 2015年 abars. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.rowHeight = UITableViewAutomaticDimension

        //refreshControl = UIRefreshControl()
        //self.refreshControl.attributedTitle = NSAttributedString(string: "引っ張って更新")
        refreshControl.addTarget(self, action: Selector("refresh"), forControlEvents: UIControlEvents.ValueChanged)
        //self.refreshControl = refreshControl
        self.tableView.addSubview(refreshControl)
        
        self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
        
        getData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // セルに表示するテキスト
    var texts:[[String]] = []
    var new_texts:[[String]] = []
    
    var refreshControl : UIRefreshControl = UIRefreshControl();

    func refresh() {
        self.getData();
        self.tableView.reloadData()
    }
    

    var regx:TDnetRegx=TDnetRegx()
    
    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
    
    func updateRegx(result:String){
        var result2:String="{\"version\":1}"
        
        result2=result.stringByReplacingOccurrencesOfString("'", withString: "\"")
        
        var dict=self.convertStringToDictionary(result2)
        
        let json = JSON(dict!)
        //for (key, subJson) in json {
        //    print(key)
        //}
        
        self.regx.VERSION=json["version"].int!
        self.regx.TDNET_ID_N=json["id_n"].int!
        self.regx.TDNET_DATE_ID=json["date_id"].int!
        self.regx.TDNET_COMPANY_ID=json["company_id"].int!
        self.regx.TDNET_COMPANY_CODE_ID=self.regx.TDNET_COMPANY_ID-1
        self.regx.TDNET_DATA_ID=json["data_id"].int!
        self.regx.TDNET_TOP_URL=json["top_url"].string!
        self.regx.TDNET_BASE_URL=json["base_url"].string!
        self.regx.TDNET_DAY_PAGE_PATTERN=json["day_page_pattern"].string!
        self.regx.TDNET_NEXT_PAGE_PATTERN=json["next_page_pattern"].string!
        self.regx.TDNET_TR_PATTERN=json["tr_pattern"].string!
        self.regx.TDNET_TD_PATTERN=json["td_pattern"].string!
        self.regx.TDNET_CONTENT_PATTERN=json["content_pattern"].string!
        
        if(self.regx.VERSION != 1){
            print("regx versin error")
            return
        }
    }
    
    func insertTable(result:String,url:String){
        /*
        let row = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.reloadRowsAtIndexPaths([row], withRowAnimation: UITableViewRowAnimation.Fade)
*/
        
        self.new_texts.append([result,url])
        /*
        self.tableView.beginUpdates()
        self.tableView.insertRowsAtIndexPaths([
            NSIndexPath(forRow: self.texts.count-1, inSection: 0)
            ], withRowAnimation: .Automatic)
        self.tableView.endUpdates()
*/
    }
    
    func updateTable(){
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        });
    }
    
    func getData() {
        let urlString = "http://tdnet-search.appspot.com/?mode=regx";
        getAsync(urlString,callback:{ result in
            self.updateRegx(result!)

            self.getAsync(self.regx.TDNET_TOP_URL,callback:{ result in
                let pattern = self.regx.TDNET_DAY_PAGE_PATTERN
                let ret:[[String]] = Regexp(pattern).groups(result!)!
                
                var next_url:String = self.regx.TDNET_BASE_URL+ret[0][1]
                print(next_url)
                
                self.new_texts=[]
                
                self.getAsync(next_url,callback:{ result in
                    self.parsePage(result!)
                });
            });
        });
    }
    
    func parsePage(result:String){
        let tr_list:[[String]]?=Regexp(self.regx.TDNET_TR_PATTERN).groups(result)
        if(tr_list != nil){
            for tr in tr_list! {
                let tr_str=tr[1]
                let td_list:[[String]]?=Regexp(self.regx.TDNET_TD_PATTERN).groups(tr_str)
                if(td_list != nil){
                    var cnt=0
                    
                    var date_id:String=""
                    var company_code_id:String=""
                    var company_id:String=""
                    var data_id:String=""
                    
                    for td in td_list! {
                        let td_str=td[1]
                        if(cnt==self.regx.TDNET_DATE_ID){
                            date_id=td_str
                        }
                        if(cnt==self.regx.TDNET_COMPANY_CODE_ID){
                            company_code_id=td_str
                        }
                        if(cnt==self.regx.TDNET_COMPANY_ID){
                            company_id=td_str
                        }
                        if(cnt==self.regx.TDNET_DATA_ID){
                            data_id=td_str
                        }
                        cnt++
                    }
                    
                    let url_list:[[String]]?=Regexp(self.regx.TDNET_CONTENT_PATTERN).groups(data_id)
                    if(url_list != nil){
                        if(cnt>=self.regx.TDNET_ID_N){
                            var data:String=url_list![0][2]
                            var url:String=url_list![0][1]
                            self.insertTable(date_id+" "+company_code_id+" "+company_id+"\n"+data,url:url)
                        }
                    }
                }
            }
        }

        //next page
        
        let pattern = self.regx.TDNET_NEXT_PAGE_PATTERN
        let next_ret = Regexp(pattern).groups(result)
        if(next_ret != nil){
            let ret:[[String]] = next_ret!
        
            var next_url:String = self.regx.TDNET_BASE_URL+ret[0][1]
            print(next_url)
        
            self.getAsync(next_url,callback:{ result_next in
                self.parsePage(result_next!)
            });
        }else{
            //last
            self.texts=self.new_texts
            self.updateTable()
            self.refreshControl.endRefreshing()
        }
    }
    
    // HTTP-GET
    func getAsync(urlString:String,callback:(String?) -> ()) {
        
        // create the url-request
        var request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        
        // set the method(HTTP-GET)
        request.HTTPMethod = "GET"
        request.cachePolicy=NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData;
        
        // use NSURLSession
        var task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { data, response, error in
            if (error == nil) {
                var result = String(data: data!, encoding: NSUTF8StringEncoding)
                callback(result)
            } else {
                print(error)
            }
        })
        task.resume()
        
    }
    
    //セルの内容を変更
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        
        cell.textLabel?.text = texts[indexPath.row][0]
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
        var url_str:String = self.regx.TDNET_BASE_URL+self.texts[indexPath.row][1];
        let url = NSURL(string: url_str)
        if UIApplication.sharedApplication().canOpenURL(url!){
            UIApplication.sharedApplication().openURL(url!)
        }
    }
}

