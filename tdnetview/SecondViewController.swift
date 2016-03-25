//
//  SecondViewController.swift
//  tdnetview
//
//  Created by abars on 2015/04/11.
//  Copyright (c) 2015年 abars. All rights reserved.
//

import UIKit

class SecondViewController: FirstViewController,UITextFieldDelegate {

    @IBOutlet weak var myTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        myTextField.delegate = self
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidDisappear(animated:Bool) {
        myTextField.text=""
        super.texts=[]
        super.updateTable()
        super.viewDidDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func textFieldShouldReturn(textField: UITextField!) -> Bool{
        print( textField.text )
        getData( textField.text! )
        return true
    }

    override func isSearchScreen() -> Bool{
        return true;
    }

}

