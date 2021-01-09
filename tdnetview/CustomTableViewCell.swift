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
    var util:Bool = false
    var view:RecentViewController? = nil;
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if(util){
            return false
        }
        if action == #selector(CustomTableViewCell.mark(_:)) || action == #selector(CustomTableViewCell.tweet(_:)) || action == #selector(CustomTableViewCell.yahoo(_:)) || action == #selector(CustomTableViewCell.remove(_:)) || action == #selector(CustomTableViewCell.search(_:)) {
            return true
        } else {
            return false
        }
    }
    
    @objc func tweet(_ sender: AnyObject) {
        DispatchQueue.main.async(execute: {
            self.view?.tweet(self.idx)
        })
    }
    
    @objc func mark(_ sender: AnyObject) {
        DispatchQueue.main.async(execute: {
            self.view?.mark(self.idx)
        })
    }

    @objc func yahoo(_ sender: AnyObject) {
        DispatchQueue.main.async(execute: {
            self.view?.yahoo(self.idx)
        })
    }
    
    @objc func remove(_ sender: AnyObject) {
        DispatchQueue.main.async(execute: {
            self.view?.remove(self.idx)
        })
    }

    @objc func search(_ sender: AnyObject) {
        DispatchQueue.main.async(execute: {
            self.view?.search(self.idx)
        })
    }
}
