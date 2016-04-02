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
    var view:RecentViewController? = nil;
    
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
        if action == #selector(CustomTableViewCell.mark(_:)) || action == #selector(CustomTableViewCell.tweet(_:)) || action == #selector(CustomTableViewCell.yahoo(_:)) || action == #selector(CustomTableViewCell.remove(_:)) || action == #selector(CustomTableViewCell.search(_:)) {
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
    
    func remove(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue(), {
            self.view?.remove(self.idx)
        })
    }

    func search(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue(), {
            self.view?.search(self.idx)
        })
    }
}