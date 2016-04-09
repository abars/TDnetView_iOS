//
//  SearchViewController
//  tdnetview
//
//  Created by abars on 2015/04/11.
//  Copyright (c) 2015年 abars. All rights reserved.
//

import UIKit
import iAd

class SearchViewController: RecentViewController,UISearchBarDelegate {

    @IBOutlet weak var mySearchBar: UISearchBar!

    var search_cache:[String]=[]
    let userDefaults = NSUserDefaults.standardUserDefaults()
    var current_view:Bool = false
    var request_query:String = ""
    var prevent_refresh:Bool = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mySearchBar.delegate = self
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func openPdf(url_str:String){
        prevent_refresh=true
        super.openPdf(url_str)
    }
    
    override func viewDidAppear(animated:Bool) {
        super.viewDidAppear(animated)

        if(!prevent_refresh){
            self.refreshList()
        }
        prevent_refresh=false;
        
        current_view=true
        if(request_query != ""){
            searchCore(request_query,update_history:false)
            request_query=""
        }
    }

    override func viewDidDisappear(animated:Bool) {
        super.viewDidDisappear(animated)

        if(!prevent_refresh){
            super.clearTable()
        }

        self.registMenuNormal()
        current_view=false
    }

    func refreshList(){
        mySearchBar.text=""
        
        var texts : [Article]=[]
        
        if(userDefaults.objectForKey("search") != nil){
            search_cache = userDefaults.objectForKey("search") as! [String]
        }
        if(search_cache.count == 0){
            search_cache.append("title:株主優待")
            search_cache.append("per>0 AND per<8 AND pbr>0 AND pbr<0.5")
        }
        for search in search_cache{
            let art:Article = Article()
            art.cell=search
            art.url="search"
            texts.append(art)
        }
        
        super.registMenuList()
        
        super.updateTable(texts)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func searchBarSearchButtonClicked(mySearchBar: UISearchBar){
        print( mySearchBar.text )
        if(mySearchBar.text != ""){
            searchCore(mySearchBar.text!,update_history: true)
        }
        mySearchBar.resignFirstResponder()
    }
    
    func searchRequest(query:String){
        if(current_view){
            searchCore(query,update_history: false)
        }else{
            request_query=query
        }
    }
    
    func searchCore(text:String,update_history:Bool){
        let art:Article = Article()
        art.cell="検索中..."
        art.url=""
        
        var new_texts : [Article] = []
        new_texts.append(art)

        self.updateTable(new_texts)
        
        mySearchBar.text=text
        
        if(update_history){
            if(search_cache.contains(text)){
                let idx:Int = search_cache.indexOf(text)!
                search_cache.removeAtIndex(idx)
            }
            search_cache.insert(text, atIndex: 0)
        }
        
        userDefaults.setObject(search_cache, forKey: "search")
        userDefaults.synchronize()
     
        super.registMenuNormal()
        
        self.search_query=text
        self.page=0
        
        refresh()
    }

    override func tableView(table: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        let url_str:String = self.texts[indexPath.row].url
        if(url_str=="search"){
            let query:String = self.texts[indexPath.row].cell
            mySearchBar.resignFirstResponder()
            searchCore(query,update_history:true)
            return
        }
        super.tableView(table, didSelectRowAtIndexPath: indexPath)
    }

    override func isSearchScreen() -> Bool{
        return true;
    }

    override func remove(idx:Int){
        let text:String = self.texts[idx].cell
        if(search_cache.contains(text)){
            let idx:Int = search_cache.indexOf(text)!
            search_cache.removeAtIndex(idx)
        }
        userDefaults.setObject(search_cache, forKey: "search")
        userDefaults.synchronize()

        self.refreshList()
    }
}

