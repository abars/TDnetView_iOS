//
//  FirstViewController.swift
//  tdnetview
//
//  Created by abars on 2015/04/11.
//  Copyright (c) 2015年 abars. All rights reserved.
//

import UIKit

class Regexp {
    let internalRegexp: NSRegularExpression
    let pattern: String
    
    init(_ pattern: String) {
        self.pattern = pattern
        self.internalRegexp = try! NSRegularExpression( pattern: pattern, options: [NSRegularExpressionOptions.CaseInsensitive ,NSRegularExpressionOptions.DotMatchesLineSeparators])
    }
    
    func isMatch(input: String) -> Bool {
        let matches = self.internalRegexp.matchesInString( input, options: [], range:NSMakeRange(0, input.characters.count) )
        return matches.count > 0
    }
    
    func matches(input: String) -> [String]? {
        if self.isMatch(input) {
            let matches = self.internalRegexp.matchesInString( input, options: [], range:NSMakeRange(0, input.characters.count) )
            var results: [String] = []
            for i in 0 ..< matches.count {
                results.append( (input as NSString).substringWithRange(matches[i].range) )
            }
            return results
        }
        return nil
    }

    func groups(input: String) -> [[String]]? {
        let matches = self.internalRegexp.matchesInString(input, options: [], range:NSMakeRange(0, input.characters.count) )
        if matches.count > 0 {
            var result: [[String]] = []
            for i in 0 ..< matches.count {
                /*
                let nsrange: NSRange = (matches[i] as NSTextCheckingResult).range
                let nsstring: NSString = input as NSString
                let group: String = nsstring.substringWithRange(nsrange)
                result.append(group)
                */
                
                var temp : [String] = []
                for var j = 0; j < matches[i].numberOfRanges; j++
                {
                    let nsstring: NSString = input as NSString
                    temp.append(nsstring.substringWithRange(matches[i].rangeAtIndex(j)))
                }
                result.append(temp)
                
            }
            return result
        } else {
            return nil
        }
    }
}

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
    //"Test abjbsikafns iojioaskdmoaskd opakopdkaopsd kopakdopksp"]
    
    var refreshControl : UIRefreshControl = UIRefreshControl();

    func refresh() {
        texts = []

        self.tableView.reloadData()
        
        self.getData();
        self.tableView.reloadData()
        
        self.refreshControl.endRefreshing()
    }
    
    struct TDnetRegx{
    var VERSION:Int=0
    var APPENGINE_BASE_URL:String="http://tdnet-search.appspot.com/"
    var TDNET_TOP_URL:String="https://www.release.tdnet.info/inbs/I_main_00.html"
    var TDNET_BASE_URL:String="https://www.release.tdnet.info/inbs/"
    var TDNET_DAY_PAGE_PATTERN:String="frame src=\"(.*)\" name=\"frame_l\""
    var TDNET_NEXT_PAGE_PATTERN:String="location=\'(.*)?\'\" type=\"button\" value=\"次画面\""
    var TDNET_TR_PATTERN:String="<tr>(.*?)</tr>"
    var TDNET_TD_PATTERN:String="<td.*?>(.*?)</td>"
    var TDNET_CONTENT_PATTERN:String="<a href=\"(.*?)\" target=.*>(.*?)</a>"
    var TDNET_ID_N:Int=4
    var TDNET_DATE_ID:Int=0
    var TDNET_COMPANY_CODE_ID:Int=1
    var TDNET_COMPANY_ID:Int=2
    var TDNET_DATA_ID:Int=3
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
        
        self.texts.append([result,url])
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
                            self.insertTable(date_id+" "+company_code_id+" "+company_id+" "+data,url:url)
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
            self.updateTable()
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

