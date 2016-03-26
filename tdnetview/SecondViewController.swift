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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mySearchBar.delegate = self
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidDisappear(animated:Bool) {
        mySearchBar.text=""
        super.texts=[]
        super.updateTable()
        super.viewDidDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func searchBarSearchButtonClicked(mySearchBar: UISearchBar!){
        print( mySearchBar.text )
        if(mySearchBar.text != ""){
            self.http_get_task.getData( mySearchBar.text! )
        }
        mySearchBar.resignFirstResponder()
        //return true
    }

    override func isSearchScreen() -> Bool{
        return true;
    }

}

