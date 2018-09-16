//
//  HttpGetTask.swift
//  tdnetview
//
//  Created by abars on 2016/03/25.
//  Copyright © 2016年 abars. All rights reserved.
//

import Foundation
import UIKit

class Article{
    init(){
        cell=""
        url=""
        tweet=""
        code=""
        cache=""
        new=false
        date=""
        attribute=nil
    }

    init(cell:String,url:String,tweet:String,code:String,cache:String,new:Bool,date:String){
        self.cell=cell
        self.url=url
        self.tweet=tweet
        self.code=code
        self.cache=cache
        self.new=new
        self.date=date
        self.attribute=nil
    }

    var cell:String
    var url:String
    var tweet:String
    var code:String
    var cache:String
    var new:Bool
    var date:String
    var attribute:NSAttributedString?
}

class HttpGetTask{
    static let MODE_RECENT:Int=0
    static let MODE_SEARCH:Int=1
    static let MODE_MARK:Int=2
    static let MODE_CRON:Int=3

    fileprivate var regx:TDnetRegx=TDnetRegx()
    fileprivate var cache_texts:[Article] = []
    fileprivate var new_texts:[Article] = []
    fileprivate var mode:Int = 0
    fileprivate var callback:(([Article])->())
    fileprivate var recent_cache:String = ""
    fileprivate var new_flag:Bool = false
    fileprivate var dark_mode:Bool = false
    fileprivate var dark_mode_font_color_css:String = ""

    init(mode:Int,dark_mode:Bool,dark_mode_font_color_css:String,callback:@escaping ([Article]) -> ()) {
        self.mode=mode
        self.dark_mode=dark_mode
        self.dark_mode_font_color_css=dark_mode_font_color_css
        self.callback=callback

        let userDefaults = UserDefaults.standard
        if(userDefaults.object(forKey: "recent") != nil){
            self.recent_cache = userDefaults.object(forKey: "recent") as! String
        }
    }

fileprivate func convertStringToDictionary(_ text: String) -> [String:AnyObject]? {
    if let data = text.data(using: String.Encoding.utf8) {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject]
        } catch let error as NSError {
            print(error)
        }
    }
    return nil
}

fileprivate func updateRegx(_ result:String){
    //swiftのjsonは""でくくる必要があるが、tdnetsearchのregxは''でくくっているので変換する
    //ただし、正規表現中の\'は退避する必要がある
    
    var result2=result.replacingOccurrences(of: "\\'", with: "[single_quortation]")
    result2=result2.replacingOccurrences(of: "'", with: "\"")
    result2=result2.replacingOccurrences(of: "[single_quortation]", with: "'")
    
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
        self.error("Regxのバージョンが不正です。",detail:"")
        return
    }
}

    fileprivate func insertTable(_ result:String,url:String,tweet:String,company_code_id:String,cache:String,new:Bool,date:String){
        let one:Article = Article()
        one.cell=result
        one.url=url
        one.tweet=tweet
        one.code=company_code_id
        one.cache=cache
        one.new=new
        one.date=date
        if(self.mode==HttpGetTask.MODE_SEARCH){
            one.attribute=convertToAttributeString(result)
        }else{
            one.attribute=nil
        }
        self.new_texts.append(one)
    }

    fileprivate func convertToAttributeString(_ cell_text:String) -> NSAttributedString?{
        if(cell_text==""){
            return nil;
        }
        
        var color:String = ""
        if(dark_mode){
            color=dark_mode_font_color_css;
        }
        let string:String = "<style>body{font-size:16px;"+color+"}</style>"+cell_text
        
        let encodedData = string.data(using: String.Encoding.utf8)!
        let attributedOptions : [String: AnyObject] = [
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType as AnyObject,
            NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue as AnyObject
        ]
        
        var attributedString:NSAttributedString?=nil
        
        do{
            attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
            return attributedString
        }catch{
            print(error)
        }
        return nil
    }
    
    func getData(_ search_str:String,page:Int,page_unit:Int) {
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
    
    func setCacheCron(_ cache:[Article]){
        self.cache_texts=cache
    }

    fileprivate func setCacheWithoutCron(){
        if(self.mode==HttpGetTask.MODE_MARK || self.mode==HttpGetTask.MODE_SEARCH){
            self.cache_texts=[]
        }else{
            self.cache_texts=self.new_texts
        }
    }
    
    fileprivate func getText(_ search_str:String,page:Int,page_unit:Int) {
        if(self.mode != HttpGetTask.MODE_CRON){
            self.setCacheWithoutCron()
        }
        
        self.new_texts=[]
        self.new_flag=true
        
        var tdnet_url = self.regx.TDNET_TOP_URL
        if(search_str != ""){
            let encoded:String = search_str.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            let page_unit:String = "page_unit="+String(page_unit)+"&page="+String(page+1)+"&"
            tdnet_url = self.regx.APPENGINE_BASE_URL+"?"+page_unit+"mode=full&query="+encoded;
            
            self.getAsync(tdnet_url,callback:{ result in
                self.parsePage(result!)
            });
            return
        }
        
        self.getAsync(tdnet_url,callback:{ result in
            if(result == nil){
                self.error("サーバとの通信に失敗しました。 ",detail:tdnet_url)
                return
            }
            
            let pattern = self.regx.TDNET_DAY_PAGE_PATTERN
            let ret:[[String]] = Regexp(pattern).groups(result!)!
            
            let next_url:String = self.regx.TDNET_BASE_URL+ret[0][1]
            //print(next_url)
            
            self.getAsync(next_url,callback:{ result in
                self.parsePage(result!)
            });
        });
    }
    
    fileprivate func truncate(_ td_str:String) -> String{
        var td_str2=td_str.replacingOccurrences(of: " ", with: "")
        td_str2=td_str2.replacingOccurrences(of: "　", with: "")
        td_str2=td_str2.replacingOccurrences(of: "\n", with: "")
        return td_str2
    }
    
    fileprivate func parsePage(_ result:String){
        let today = getToday()
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
                    
                    let cache_str : String = ""+company_id+data_id;
                    
                    if(self.cache_texts.count>=1){
                        if(self.cache_texts[0].cache==cache_str && cache_str != ""){
                            print("cache_hit")
                            cache_hit=true
                            break
                        }
                    }
                    if(self.recent_cache==cache_str && cache_str != "" && self.mode==HttpGetTask.MODE_RECENT){
                        self.new_flag=false;
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
                                cell_text = cell_text.replacingOccurrences(of: "\n", with: "<br/>")
                            }
                            
                            let tweet_text:String = ""+company_id+" "+data+" "+url
                            
                            self.insertTable(cell_text,url:url,tweet:tweet_text,company_code_id:company_code_id,cache:cache_str,new:self.new_flag,date:today)
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
            for cache in self.cache_texts{
                cache.new=false
            }
            self.new_texts.append(contentsOf: self.cache_texts)
        }
        
        //recent cache
        if(self.new_texts.count>=1 && self.mode==HttpGetTask.MODE_RECENT){
            setArticleCache();
        }

        if(self.new_texts.count==0){
            self.insertTable("開示情報は見つかりませんでした",url:"",tweet:"",company_code_id: "",cache:"",new:false,date:"")
        }
            
        DispatchQueue.main.async(execute: {
            self.callback(self.new_texts)
        })
    }
    
    fileprivate func setArticleCache(){
        self.recent_cache=self.new_texts[0].cache
        let userDefaults = UserDefaults.standard
        userDefaults.set(self.recent_cache, forKey: "recent")
        
        let newDatas:[NSDictionary] = self.new_texts.map{
            ["cell":$0.cell,
                "url":$0.url,
                "tweet":$0.tweet,
                "code":$0.code,
                "cache":$0.cache,
                "new":$0.new,
                "date":$0.date
             ] as NSDictionary
        }

        userDefaults.set(newDatas,forKey:"recent_array")
        userDefaults.synchronize()
    }
    
    fileprivate func getToday() -> String{
        let now = Date()
        
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        
        let today = format.string(from: now)
        return today
    }
    
    func getArticleCache() -> [Article]{
        let userDefaults = UserDefaults.standard
        let datas = userDefaults.object(forKey: "recent_array") as? [NSDictionary] ?? []
        // 保存されたデータから復元出来無い場合もあり得るので、
        // mapではなくreduceを使う
        let today = getToday()
        let array = datas.reduce([]){ (ary, d:NSDictionary) -> [Article] in
            // dateやmessageがnilでないなら、MyLogDataを作って足し込む
            if let cell = d["cell"]    as? String,
                let url = d["url"] as? String,
                let tweet = d["tweet"] as? String,
                let code = d["code"] as? String,
                let cache = d["cache"] as? String,
                let new = d["new"] as? Bool,
                let date = d["date"] as? String
            {
                if(today == date){
                    return ary + [Article(cell: cell, url: url, tweet:tweet , code:code,cache:cache,new:new,date:date)]
                }else{
                    return ary
                }
            }else{
                return ary
            }
        }
        return array
        
        //userDefaults.getObject(self.new_texts,forKey: "recent_array")
    }
    
    fileprivate func error(_ message:String,detail:String){
        print(message)
        self.new_texts=[]
        self.insertTable(message,url:"",tweet:"",company_code_id: "",cache:"",new:false,date:"")
        DispatchQueue.main.async(execute: {
            self.callback(self.new_texts)
        })
    }

    // HTTP-GET
    fileprivate func getAsync(_ urlString:String,callback:@escaping (String?) -> ()) {
        getAsyncCore(urlString,retry:false,callback:callback);
    }
    
    fileprivate func getAsyncCore(_ urlString:String,retry:Bool,callback:@escaping (String?) -> ()) {
        // create the url-request
        let request = NSMutableURLRequest(url: URL(string: urlString)!)
        //print(urlString)
        
        // set the method(HTTP-GET)
        request.httpMethod = "GET"
        request.cachePolicy=NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData;
        
        // use NSURLSession
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                if(httpResponse.statusCode != 200){
                    if(retry==false){
                        self.getAsyncCore(urlString,retry:true,callback:callback)
                        return
                    }
                    print(urlString)
                    self.error("サーバとの通信に失敗しました。 ",detail:String(httpResponse.statusCode))
                    return
                }
            }
            if (error == nil) {
                let result = String(data: data!, encoding: String.Encoding.utf8)
                callback(result)
            } else {
                if(retry==false){
                    self.getAsyncCore(urlString,retry:true,callback:callback)
                    return
                }
                self.error("サーバとの通信に失敗しました。 ",detail:String(describing:error))
                return
            }
        })
        task.resume()
    }
    

}

