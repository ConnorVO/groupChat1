//
//  Message.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 10/6/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    var fromId: String?
    var timestamp: NSNumber?
    var text: String?
    var groupId: String?
    
    var imageURL: String?
    var imageHeight: NSNumber?
    var imageWidth: NSNumber?
    
    /*func chatPartnerId() -> String? {
        return fromId == FIRAuth.auth()?.currentUser?.uid ? toId : fromId
    }*/
    
    init(dictionary: [String: AnyObject]) {
        super.init()
        
        fromId = dictionary["fromId"] as? String
        timestamp = dictionary["timestamp"] as? NSNumber
        text = dictionary["text"] as? String
        groupId = dictionary["groupId"] as? String
        
        imageURL = dictionary["imageURL"] as? String
        imageHeight = dictionary["imageHeight"] as? NSNumber
        imageWidth = dictionary["imageWidth"] as? NSNumber
    }
}
