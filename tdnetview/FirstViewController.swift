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

        //refreshControl = UIRefreshControl()
        //self.refreshControl.attributedTitle = NSAttributedString(string: "引っ張って更新")
        refreshControl.addTarget(self, action: Selector("refresh"), forControlEvents: UIControlEvents.ValueChanged)
        //self.refreshControl = refreshControl
        self.tableView.addSubview(refreshControl)
        
        getData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // セルに表示するテキスト
    var texts = ["Test"]
    
    var refreshControl : UIRefreshControl = UIRefreshControl();

    func refresh() {
        //var sortedAlphabet = alphabet.reverse()
        
        //for (index, element) in enumerate(sortedAlphabet) {
        //    alphabet[index] = element
        //}
        print("sort")
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
    
    func getData() {
        let urlString = "http://tdnet-search.appspot.com/?mode=regx";
        getAsync(urlString,callback:{ result in
            
            var result2:String="{\"version\":1}"
            
            result2=result!.stringByReplacingOccurrencesOfString("'", withString: "\"")
            
            var dict=self.convertStringToDictionary(result2)

            let json = JSON(dict!)
            for (key, subJson) in json {
                print(key)
            }
            
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
            
            let row = NSIndexPath(forRow: 0, inSection: 0)
            self.tableView.reloadRowsAtIndexPaths([row], withRowAnimation: UITableViewRowAnimation.Fade)
            
            self.texts.append(result!)
            
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexPaths([
                NSIndexPath(forRow: self.texts.count-1, inSection: 0)
                ], withRowAnimation: .Automatic)
            self.tableView.endUpdates()
            
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
            });
        });
    }
    
    // HTTP-GET
    func getAsync(urlString:String,callback:(String?) -> ()) {
        
        // create the url-request
        var request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        
        // set the method(HTTP-GET)
        request.HTTPMethod = "GET"
        
        // use NSURLSession
        var task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { data, response, error in
            if (error == nil) {
                var result = String(data: data!, encoding: NSUTF8StringEncoding)
                callback(result)
            } else {
                //print(error)
            }
        })
        task.resume()
        
    }
    
    //セルの内容を変更
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        
        cell.textLabel?.text = texts[indexPath.row]
        return cell
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return texts.count
    }

    func tableView(table: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        print(texts[indexPath.row])
    }
    
    //func updateCell(cell:UITableViewCell,atIndexPath:NSIndexPath) {
        
    //}
}

