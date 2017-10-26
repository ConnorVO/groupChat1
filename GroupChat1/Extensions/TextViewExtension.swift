//
//  TextViewExtension.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 10/19/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit

//not currently used
extension UITextView {
    func numberOfLines() -> Int {
        let layoutManager = self.layoutManager
        let numberOfGlyphs = layoutManager.numberOfGlyphs
        var lineRange: NSRange = NSMakeRange(0, 1)
        var index = 0
        var numberOfLines = 0
        
        while index < numberOfGlyphs {
            layoutManager.lineFragmentRect(
                forGlyphAt: index, effectiveRange: &lineRange
            )
            index = NSMaxRange(lineRange)
            numberOfLines += 1
        }
        return numberOfLines
    }
}
