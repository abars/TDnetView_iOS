//
//  Mark.swift
//  tdnetview
//
//  Created by abars on 2016/03/26.
//  Copyright © 2016年 abars. All rights reserved.
//

import Foundation

class Mark{
    var mark_list:[String] = []
    var is_updated_flag:Bool = false
    
    init() {
        let userDefaults = UserDefaults.standard
        if(userDefaults.object(forKey: "mark") != nil){
            mark_list = userDefaults.object(forKey: "mark") as! [String]
        }
    }
    
    func add_remove(_ company_id:String){
        if(mark_list.contains(company_id)){
            let idx:Int = mark_list.firstIndex(of: company_id)!
            mark_list.remove(at: idx)
        }else{
            mark_list.insert(company_id, at: 0)
        }

        let userDefaults = UserDefaults.standard
        userDefaults.set(mark_list, forKey: "mark")
        userDefaults.synchronize()
        
        is_updated_flag=true
    }
    
    func is_mark(_ company_id:String) -> Bool{
        return mark_list.contains(company_id)
    }
    
    func get_query() -> String{
        var query : String=""
        for i in 0..<mark_list.count{
            if(i != 0){
                query+=" OR ";
            }
            query+="code:"+mark_list[i]
        }
        if(query==""){
            return "code:not_found"
        }
        return ""+query+"";
    }
    
    func is_updated() -> Bool{
        let ret:Bool = is_updated_flag
        return ret
    }
    
    func clear_update_flag(){
        is_updated_flag=false
    }
}
