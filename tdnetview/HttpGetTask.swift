//
//  HttpGetTask.swift
//  tdnetview
//
//  Created by abars on 2016/03/25.
//  Copyright © 2016年 abars. All rights reserved.
//

import Foundation

class Article{
    init(){
        cell=""
        url=""
        tweet=""
        code=""
        cache=""
    }
    
    var cell:String
    var url:String
    var tweet:String
    var code:String
    var cache:String
}

class HttpGetTask{

var regx:TDnetRegx=TDnetRegx()
var cache_texts:[Article] = []
var new_texts:[Article] = []
var first_view:FirstViewController;

init(_ view: FirstViewController) {
    self.first_view=view
}

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
    //swiftのjsonは""でくくる必要があるが、tdnetsearchのregxは''でくくっているので変換する
    //ただし、正規表現中の\'は退避する必要がある
    
    var result2=result.stringByReplacingOccurrencesOfString("\\'", withString: "[single_quortation]")
    result2=result2.stringByReplacingOccurrencesOfString("'", withString: "\"")
    result2=result2.stringByReplacingOccurrencesOfString("[single_quortation]", withString: "'")
    
    var dict=self.convertStringToDictionary(result2)
    
    let json = JSON(dict!)
    
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

    func insertTable(result:String,url:String,tweet:String,company_code_id:String){
    /*
    let row = NSIndexPath(forRow: 0, inSection: 0)
    self.tableView.reloadRowsAtIndexPaths([row], withRowAnimation: UITableViewRowAnimation.Fade)
    */
    
        var one:Article = Article()
        one.cell=result
        one.url=url
        one.tweet=tweet
        one.code=company_code_id
        
        self.new_texts.append(one)
    /*
    self.tableView.beginUpdates()
    self.tableView.insertRowsAtIndexPaths([
    NSIndexPath(forRow: self.texts.count-1, inSection: 0)
    ], withRowAnimation: .Automatic)
    self.tableView.endUpdates()
    */
}

    func getData(search_str:String) {
        if(regx.VERSION==0){
            let urlString = self.regx.APPENGINE_BASE_URL+"?mode=regx"
            getAsync(urlString,callback:{ result in
                self.updateRegx(result!)
                self.getText(search_str)
            });
        }else{
            self.getText(search_str)
        }
    }
    
    func getText(search_str:String) {
        self.cache_texts=self.new_texts
        self.new_texts=[]
        
        var tdnet_url = self.regx.TDNET_TOP_URL
        if(search_str != ""){
            var encoded:String = search_str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            var page_unit:String = "page_unit="+String(100)+"&"
            tdnet_url = self.regx.APPENGINE_BASE_URL+"?"+page_unit+"mode=full&query="+encoded;
            
            self.getAsync(tdnet_url,callback:{ result in
                self.parsePage(result!)
            });
            return
        }
        
        self.getAsync(tdnet_url,callback:{ result in
            let pattern = self.regx.TDNET_DAY_PAGE_PATTERN
            let ret:[[String]] = Regexp(pattern).groups(result!)!
            
            var next_url:String = self.regx.TDNET_BASE_URL+ret[0][1]
            print(next_url)
            
            self.getAsync(next_url,callback:{ result in
                self.parsePage(result!)
            });
        });
    }
    
    func truncate(td_str:String) -> String{
        var td_str2=td_str.stringByReplacingOccurrencesOfString(" ", withString: "")
        td_str2=td_str2.stringByReplacingOccurrencesOfString("　", withString: "")
        td_str2=td_str2.stringByReplacingOccurrencesOfString("\n", withString: "")
        return td_str2
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
                    var full:String=""
                    
                    for td in td_list! {
                        let td_str=td[1]
                        if(cnt==self.regx.TDNET_DATE_ID){
                            date_id=self.truncate(td_str)
                        }
                        if(cnt==self.regx.TDNET_COMPANY_CODE_ID){
                            company_code_id=self.truncate(td_str)
                        }
                        if(cnt==self.regx.TDNET_COMPANY_ID){
                            company_id=self.truncate(td_str)
                        }
                        if(cnt==self.regx.TDNET_DATA_ID){
                            data_id=td_str
                        }
                        if(cnt==self.regx.TDNET_DATA_ID+1){
                            if(first_view.isSearchScreen()){
                                full=td_str;
                            }
                        }
                        cnt++
                    }
                    
                    //if(self.first_view.isMarkScreen()){
                    //    if(!self.first_view.mark.is_mark(company_id)){
                    //        continue
                    //    }
                    //}
                    
                    let url_list:[[String]]?=Regexp(self.regx.TDNET_CONTENT_PATTERN).groups(data_id)
                    if(url_list != nil){
                        if(cnt>=self.regx.TDNET_ID_N){
                            var data:String=self.truncate(url_list![0][2])
                            var prefix:String=self.regx.TDNET_BASE_URL
                            if(self.first_view.isSearchScreen() || self.first_view.isMarkScreen()){
                                prefix=self.regx.APPENGINE_BASE_URL
                            }
                            if(Regexp("日々の開示").matches(data) != nil){
                                continue
                            }
                            var url:String=prefix+url_list![0][1]
                            var sep:String="\n"
                            
                            if(full != ""){
                                full=""+sep+sep+full
                            }
                            
                            var space:String="　"
                            if(self.first_view.isSearchScreen()){
                                space="&nbsp;"
                            }
                            
                            var cell_text:String = ""+date_id+space+company_code_id+space+company_id+sep+data+full

                            if(self.first_view.isSearchScreen()){
                                cell_text = cell_text.stringByReplacingOccurrencesOfString("\n", withString: "<br/>")
                            }
                            
                            var tweet_text:String = ""+company_id+" "+data+" "+url
                            
                            self.insertTable(cell_text,url:url,tweet:tweet_text,company_code_id:company_code_id)
                        }
                    }
                }
            }
        }
        
        //next page
        
        var pattern = self.regx.TDNET_NEXT_PAGE_PATTERN
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
            if(self.new_texts.count==0){
                self.insertTable("no data found",url:"",tweet:"",company_code_id: "")
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.first_view.texts=self.new_texts
                self.first_view.updateTable()
            })
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
    

}

