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
        if action == "remove:" || action == "edit:" || action == "regist:" {
            return true
        } else {
            return false
        }
    }
    
    func remove(sender: AnyObject) {
        // 削除を押したときに呼ばれる
        //var indexPath = self.tableView.indexPathForSelectedRow;
        // copy content to pasteboard
        //NSString *string = self.list[indexPath.row];
        //[UIPasteboard generalPasteboard].string = string;
        view?.tweet(idx)

    }
    
    func edit(sender: AnyObject) {
        // 編集を押したときに呼ばれる
    }
    
    func regist(sender: AnyObject) {
        // 登録を押したときに呼ばれる
    }
}