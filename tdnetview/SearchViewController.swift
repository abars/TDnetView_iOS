//
//  SearchViewController
//  tdnetview
//
//  Created by abars on 2015/04/11.
//  Copyright (c) 2015年 abars. All rights reserved.
//

import UIKit

class SearchViewController: RecentViewController,UISearchBarDelegate , GADBannerViewDelegate {

    @IBOutlet weak var mySearchBar: UISearchBar!

    var search_cache:[String]=[]
    let userDefaults = UserDefaults.standard
    var current_view:Bool = false
    var request_query:String = ""
    var prevent_refresh:Bool = false
    var is_ad_enable:Bool = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mySearchBar.delegate = self
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func openPdf(_ url_str:String){
        prevent_refresh=true
        super.openPdf(url_str)
    }
    
    override func viewDidAppear(_ animated:Bool) {
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
    
    func backToTop(){
        refreshList();
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if(is_ad_enable){
            return 50.0
        }else{
            return 0.0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if(!is_ad_enable){
            return nil
        }
        var bannerView: GADBannerView = GADBannerView()
        bannerView = GADBannerView(adSize:GADAdSizeBanner)
        bannerView.adUnitID = "ca-app-pub-8699119390634135/7750253209"
        bannerView.delegate = self
        bannerView.rootViewController = self
        
        let x:CGFloat = 0;//(tableView.frame.width - bannerView.frame.size.width)/2;
        let y:CGFloat = 0;
        bannerView.frame = CGRect(x: x, y: y, width: bannerView.frame.size.width, height: bannerView.frame.size.height);
        
        let request=GADRequest()
        //request.testDevices = [ "9bdf501780072be275b683e5449b231b", GADSimulatorID ]
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ GADSimulatorID ]
        bannerView.load(request)
        
        return bannerView
    }
    
    override func viewDidDisappear(_ animated:Bool) {
        super.viewDidDisappear(animated)

        if(!prevent_refresh){
            super.clearTable()
        }

        current_view=false
    }

    func refreshList(){
        mySearchBar.text=""
        
        var texts : [Article]=[]
        
        if(userDefaults.object(forKey: "search") != nil){
            search_cache = userDefaults.object(forKey: "search") as! [String]
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
        is_ad_enable=true
        
        super.updateTable(texts)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func searchBarSearchButtonClicked(_ mySearchBar: UISearchBar){
        print( mySearchBar.text )
        if(mySearchBar.text != ""){
            searchCore(mySearchBar.text!,update_history: true)
        }
        mySearchBar.resignFirstResponder()
    }
    
    func searchRequest(_ query:String){
        if(current_view){
            searchCore(query,update_history: false)
        }else{
            request_query=query
        }
    }
    
    func searchCore(_ text:String,update_history:Bool){
        self.showMessage("検索中...")
        
        mySearchBar.text=text
        
        if(update_history){
            if(search_cache.contains(text)){
                let idx:Int = search_cache.firstIndex(of: text)!
                search_cache.remove(at: idx)
            }
            search_cache.insert(text, at: 0)
        }
        
        userDefaults.set(search_cache, forKey: "search")
        userDefaults.synchronize()
     
        super.registMenuNormal()
        is_ad_enable=false
        
        self.search_query=text
        self.page=0
        
        refresh()
    }

    override func tableView(_ table: UITableView, didSelectRowAt indexPath:IndexPath) {
        let url_str:String = self.texts[indexPath.row].url
        if(url_str=="search"){
            let query:String = self.texts[indexPath.row].cell
            mySearchBar.resignFirstResponder()
            searchCore(query,update_history:true)
            return
        }
        super.tableView(table, didSelectRowAt: indexPath)
    }

    override func isSearchScreen() -> Bool{
        return true;
    }

    override func remove(_ idx:Int){
        let text:String = self.texts[idx].cell
        if(search_cache.contains(text)){
            let idx:Int = search_cache.firstIndex(of: text)!
            search_cache.remove(at: idx)
        }
        userDefaults.set(search_cache, forKey: "search")
        userDefaults.synchronize()

        self.refreshList()
    }
}

