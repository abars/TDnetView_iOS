//
//  SecondViewController.swift
//  tdnetview
//
//  Created by abars on 2015/04/11.
//  Copyright (c) 2015年 abars. All rights reserved.
//

import UIKit

class SecondViewController: FirstViewController,UISearchBarDelegate {

    @IBOutlet weak var mySearchBar: UISearchBar!

    var search_cache:[String]=[]
    let userDefaults = NSUserDefaults.standardUserDefaults()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mySearchBar.delegate = self
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated:Bool) {
        self.refreshList()
        super.viewDidAppear(animated)
    }

    func refreshList(){
        mySearchBar.text=""
        
        super.texts=[]
        
        if(userDefaults.objectForKey("search") != nil){
            search_cache = userDefaults.objectForKey("search") as! [String]
            if(search_cache.count == 0){
                search_cache.append("title:株主優待")
                search_cache.append("per>0 AND per<8 AND pbr>0 AND pbr<0.5")
            }
            for search in search_cache{
                let art:Article = Article()
                art.cell=search
                art.url="search"
                super.texts.append(art)
            }
        }
        
        super.registMenuList()
        
        super.updateTable()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func searchBarSearchButtonClicked(mySearchBar: UISearchBar){
        print( mySearchBar.text )
        if(mySearchBar.text != ""){
            searchCore(mySearchBar.text!)
        }
        mySearchBar.resignFirstResponder()
        //return true
    }
    
    func searchCore(text:String){
        self.texts=[]
        self.updateTable()
        
        if(search_cache.contains(text)){
            let idx:Int = search_cache.indexOf(text)!
            search_cache.removeAtIndex(idx)
        }
        search_cache.insert(text, atIndex: 0)
        
        userDefaults.setObject(search_cache, forKey: "search")
        userDefaults.synchronize()
     
        super.registMenuNormal()

        self.http_get_task.getData( text )
    }

    override func tableView(table: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        let url_str:String = self.texts[indexPath.row].url
        if(url_str=="search"){
            let query:String = self.texts[indexPath.row].cell
            mySearchBar.text=query
            searchCore(query)
            return
        }
        super.tableView(table, didSelectRowAtIndexPath: indexPath)
    }

    override func isSearchScreen() -> Bool{
        return true;
    }

    override func remove(idx:Int){
        print("remove")
        let text:String = self.texts[idx].cell
        if(search_cache.contains(text)){
            let idx:Int = search_cache.indexOf(text)!
            print(idx)
            search_cache.removeAtIndex(idx)
        }
        userDefaults.setObject(search_cache, forKey: "search")
        userDefaults.synchronize()

        self.refreshList()
    }
}

