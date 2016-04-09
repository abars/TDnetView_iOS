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

    static let MODE_RECENT:Int=0
    static let MODE_SEARCH:Int=1
    static let MODE_MARK:Int=2
    static let MODE_CRON:Int=3

    private var regx:TDnetRegx=TDnetRegx()
    private var cache_texts:[Article] = []
    private var new_texts:[Article] = []
    private var mode:Int = 0
    private var callback:([Article]->());

    init(mode:Int,callback:([Article]) -> ()) {
        self.mode=mode
        self.callback=callback
    }

private func convertStringToDictionary(text: String) -> [String:AnyObject]? {
    if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
        do {
            return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]
        } catch let error as NSError {
            print(error)
        }
    }
    return nil
}

private func updateRegx(result:String){
    //swiftのjsonは""でくくる必要があるが、tdnetsearchのregxは''でくくっているので変換する
    //ただし、正規表現中の\'は退避する必要がある
    
    var result2=result.stringByReplacingOccurrencesOfString("\\'", withString: "[single_quortation]")
    result2=result2.stringByReplacingOccurrencesOfString("'", withString: "\"")
    result2=result2.stringByReplacingOccurrencesOfString("[single_quortation]", withString: "'")
    
    let dict=self.convertStringToDictionary(result2)
    
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
        self.error("Regxのバージョンが不正です。")
        return
    }
}

    private func insertTable(result:String,url:String,tweet:String,company_code_id:String,cache:String){
        let one:Article = Article()
        one.cell=result
        one.url=url
        one.tweet=tweet
        one.code=company_code_id
        one.cache=cache
        
        self.new_texts.append(one)
    }

    func getData(search_str:String,page:Int,page_unit:Int) {
        if(regx.VERSION==0){
            let urlString = self.regx.APPENGINE_BASE_URL+"?mode=regx"
            getAsync(urlString,callback:{ result in
                self.updateRegx(result!)
                self.getText(search_str,page:page,page_unit:page_unit)
            });
        }else{
            self.getText(search_str,page:page,page_unit:page_unit)
        }
    }
    
    func setCacheCron(cache:[Article]){
        self.cache_texts=cache
    }

    private func setCacheWithoutCron(){
        if(self.mode==HttpGetTask.MODE_MARK || self.mode==HttpGetTask.MODE_SEARCH){
            self.cache_texts=[]
        }else{
            self.cache_texts=self.new_texts
        }
    }
    
    private func getText(search_str:String,page:Int,page_unit:Int) {
        if(self.mode != HttpGetTask.MODE_CRON){
            self.setCacheWithoutCron()
        }
        self.new_texts=[]
        
        var tdnet_url = self.regx.TDNET_TOP_URL
        if(search_str != ""){
            let encoded:String = search_str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            let page_unit:String = "page_unit="+String(page_unit)+"&page="+String(page+1)+"&"
            tdnet_url = self.regx.APPENGINE_BASE_URL+"?"+page_unit+"mode=full&query="+encoded;
            
            self.getAsync(tdnet_url,callback:{ result in
                self.parsePage(result!)
            });
            return
        }
        
        self.getAsync(tdnet_url,callback:{ result in
            let pattern = self.regx.TDNET_DAY_PAGE_PATTERN
            let ret:[[String]] = Regexp(pattern).groups(result!)!
            
            let next_url:String = self.regx.TDNET_BASE_URL+ret[0][1]
            //print(next_url)
            
            self.getAsync(next_url,callback:{ result in
                self.parsePage(result!)
            });
        });
    }
    
    private func truncate(td_str:String) -> String{
        var td_str2=td_str.stringByReplacingOccurrencesOfString(" ", withString: "")
        td_str2=td_str2.stringByReplacingOccurrencesOfString("　", withString: "")
        td_str2=td_str2.stringByReplacingOccurrencesOfString("\n", withString: "")
        return td_str2
    }
    
    private func parsePage(result:String){
        let tr_list:[[String]]?=Regexp(self.regx.TDNET_TR_PATTERN).groups(result)
        var cache_hit=false
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
                            if(self.mode==HttpGetTask.MODE_SEARCH){
                                full=td_str;
                            }
                        }
                        cnt=cnt+1
                    }
                    
                    if(self.cache_texts.count>=1){
                        if(self.cache_texts[0].cache==tr_str){
                            print("cache_hit")
                            cache_hit=true
                            break
                        }
                    }
                    
                    let url_list:[[String]]?=Regexp(self.regx.TDNET_CONTENT_PATTERN).groups(data_id)
                    if(url_list != nil){
                        if(cnt>=self.regx.TDNET_ID_N){
                            let data:String=self.truncate(url_list![0][2])
                            var prefix:String=self.regx.TDNET_BASE_URL
                            if(self.mode==HttpGetTask.MODE_SEARCH || self.mode==HttpGetTask.MODE_MARK){
                                prefix=self.regx.APPENGINE_BASE_URL
                            }
                            if(Regexp("日々の開示").matches(data) != nil){
                                continue
                            }
                            let url:String=prefix+url_list![0][1]
                            let sep:String="\n"
                            
                            if(full != ""){
                                full=""+sep+sep+full
                            }
                            
                            var space:String="　"
                            if(self.mode==HttpGetTask.MODE_SEARCH){
                                space="&nbsp;"
                            }
                            
                            var cell_text:String = ""+date_id+space+company_code_id+space+company_id+sep+data+full

                            if(self.mode==HttpGetTask.MODE_SEARCH){
                                cell_text = cell_text.stringByReplacingOccurrencesOfString("\n", withString: "<br/>")
                            }
                            
                            let tweet_text:String = ""+company_id+" "+data+" "+url
                            
                            self.insertTable(cell_text,url:url,tweet:tweet_text,company_code_id:company_code_id,cache:tr_str)
                        }
                    }
                }
            }
        }
        
        //next page
        
        let pattern = self.regx.TDNET_NEXT_PAGE_PATTERN
        let next_ret = Regexp(pattern).groups(result)
        
        if(next_ret != nil && cache_hit==false){
            let ret:[[String]] = next_ret!
            
            let next_url:String = self.regx.TDNET_BASE_URL+ret[0][1]
            if(next_url != regx.TDNET_BASE_URL){
                self.getAsync(next_url,callback:{ result_next in
                    self.parsePage(result_next!)
                });
                return
            }
        }
        
        //last
        if(cache_hit){
            self.new_texts.appendContentsOf(self.cache_texts)
        }

        if(self.new_texts.count==0){
            self.insertTable("開示情報は見つかりませんでした",url:"",tweet:"",company_code_id: "",cache:"")
        }
            
        dispatch_async(dispatch_get_main_queue(), {
            self.callback(self.new_texts)
        })
    }
    
    private func error(message:String){
        print(message)
        self.new_texts=[]
        self.insertTable(message,url:"",tweet:"",company_code_id: "",cache:"")
        dispatch_async(dispatch_get_main_queue(), {
            self.callback(self.new_texts)
        })
    }

    // HTTP-GET
    private func getAsync(urlString:String,callback:(String?) -> ()) {
        // create the url-request
        let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        //print(urlString)
        
        // set the method(HTTP-GET)
        request.HTTPMethod = "GET"
        request.cachePolicy=NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData;
        
        // use NSURLSession
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { data, response, error in
            if let httpResponse = response as? NSHTTPURLResponse {
                if(httpResponse.statusCode != 200){
                    print(urlString)
                    self.error("サーバとの通信に失敗しました。 "+String(httpResponse.statusCode))
                    return
                }
            }
            if (error == nil) {
                let result = String(data: data!, encoding: NSUTF8StringEncoding)
                callback(result)
            } else {
                self.error("サーバとの通信に失敗しました。 "+String(error))
                return
            }
        })
        task.resume()
        
    }
    

}

