//
//  Mark.swift
//  tdnetview
//
//  Created by abars on 2016/03/26.
//  Copyright © 2016年 abars. All rights reserved.
//

import Foundation

class Mark{
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    var mark_list:[String] = []
    
    init() {
        if(userDefaults.objectForKey("mark") != nil){
            mark_list = userDefaults.objectForKey("mark") as! [String]
        }
    }
    
    func add_remove(company_id:String){
        if(mark_list.contains(company_id)){
            var idx:Int = mark_list.indexOf(company_id)!
            mark_list.removeAtIndex(idx)
        }else{
            mark_list.insert(company_id, atIndex: 0)
        }

        userDefaults.setObject(mark_list, forKey: "mark")
        userDefaults.synchronize()
    }
    
    func is_mark(company_id:String) -> Bool{
        return mark_list.contains(company_id)
    }
}
