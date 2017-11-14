//
//  RandomAlphanumericKey.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 10/31/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit

class RandomAlphanumericKey {
    static func randomAlphanumericString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
}
