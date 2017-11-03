//
//  MyTabBarController.swift
//  tdnetview
//
//  Created by abars on 2017/01/22.
//  Copyright © 2017年 abars. All rights reserved.
//

import Foundation

class MyTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate;
        
        let currentVC = self.selectedViewController
        if currentVC==viewController{
        }else{
            return true
        }

        if viewController is SearchViewController {
            appDelegate.searchScreenSelected();
        }
        if viewController is MarkViewController {
            appDelegate.markScreenSelected();
        }
        if viewController is RecentViewController {
            appDelegate.recentScreenSelected();
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
