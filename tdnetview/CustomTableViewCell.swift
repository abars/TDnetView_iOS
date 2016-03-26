//
//  CustomTableViewCell.swift
//  tdnetview
//
//  Created by abars on 2016/03/25.
//  Copyright © 2016年 abars. All rights reserved.
//

import UIKit
import Foundation

class CustomTableViewCell: UITableViewCell
{
    var idx:Int = -1;
    var view:FirstViewController? = nil;
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    // 必要なメニューのみ表示します
    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        if action == "mark:" || action == "tweet:" || action == "yahoo:"{
            return true
        } else {
            return false
        }
    }
    
    func tweet(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue(), {
            self.view?.tweet(self.idx)
        })
    }
    
    func mark(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue(), {
            self.view?.mark(self.idx)
        })
    }

    func yahoo(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue(), {
            self.view?.yahoo(self.idx)
        })
    }
}