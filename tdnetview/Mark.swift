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
    
    init() {
    }
    
    func add_remove(company_id:String){
        mark_list.insert(company_id, atIndex: 0)
    }
    
    func is_mark(company_id:String) -> Bool{
        return false
    }
}
