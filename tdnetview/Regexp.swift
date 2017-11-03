//
//  Regexp.swift
//  tdnetview
//
//  Created by abars on 2016/03/25.
//  Copyright © 2016年 abars. All rights reserved.
//

import Foundation

class Regexp {
    let internalRegexp: NSRegularExpression
    let pattern: String
    
    init(_ pattern: String) {
        self.pattern = pattern
        self.internalRegexp = try! NSRegularExpression( pattern: pattern, options: [NSRegularExpression.Options.caseInsensitive ,NSRegularExpression.Options.dotMatchesLineSeparators])
    }
    
    func isMatch(_ input: String) -> Bool {
        let matches = self.internalRegexp.matches( in: input, options: [], range:NSMakeRange(0, input.characters.count) )
        return matches.count > 0
    }
    
    func matches(_ input: String) -> [String]? {
        if self.isMatch(input) {
            let matches = self.internalRegexp.matches( in: input, options: [], range:NSMakeRange(0, input.characters.count) )
            var results: [String] = []
            for i in 0 ..< matches.count {
                results.append( (input as NSString).substring(with: matches[i].range) )
            }
            return results
        }
        return nil
    }
    
    func groups(_ input: String) -> [[String]]? {
        let matches = self.internalRegexp.matches(in: input, options: [], range:NSMakeRange(0, input.characters.count) )
        if matches.count > 0 {
            var result: [[String]] = []
            for i in 0 ..< matches.count {
                /*
                let nsrange: NSRange = (matches[i] as NSTextCheckingResult).range
                let nsstring: NSString = input as NSString
                let group: String = nsstring.substringWithRange(nsrange)
                result.append(group)
                */
                
                var temp : [String] = []
                for j in 0..<matches[i].numberOfRanges
                {
                    let nsstring: NSString = input as NSString
                    temp.append(nsstring.substring(with: matches[i].rangeAt(j)))
                }
                result.append(temp)
                
            }
            return result
        } else {
            return nil
        }
    }
}

