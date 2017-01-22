//
//  MyTabBarController.swift
//  tdnetview
//
//  Created by abars on 2017/01/22.
//  Copyright © 2017年 abars. All rights reserved.
//

import Foundation

class MyTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        
        if viewController is SearchViewController {
            // DummyViewControllerはモーダルを出したい特定のタブに紐付けたViewController
            //if let currentVC = self.selectedViewController{
                /*
                 //表示させるモーダル
                let modalViewController: UIViewController = UIViewController()
                //わかりやすく背景を赤色に
                modalViewController.view.backgroundColor = UIColor.redColor()
                currentVC.presentViewController(modalViewController, animated: true, completion: nil)
                */
                    
            //}
            
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate;
            appDelegate.searchScreenSelected();
            
                
            return true;//false
        }
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
