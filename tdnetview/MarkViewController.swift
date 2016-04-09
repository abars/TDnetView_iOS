//
//  SecondViewController.swift
//  tdnetview
//
//  Created by abars on 2015/04/11.
//  Copyright (c) 2015年 abars. All rights reserved.
//

import UIKit

class MarkViewController: RecentViewController,UISearchBarDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(animated:Bool) {
        super.viewDidAppear(animated)

        if(mark.is_updated()){
            mark.clear_update_flag()
            refresh()
        }

        self.registMenuMark()
    }

    override func viewDidDisappear(animated:Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func isSearchScreen() -> Bool{
        return false;
    }
    
    override func isMarkScreen() -> Bool{
        return true;
    }
}

