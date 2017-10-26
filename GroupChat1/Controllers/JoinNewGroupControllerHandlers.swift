//
//  JoinNewGroupControllerHandlers.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 10/3/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit
import Firebase

extension JoinNewGroupController {
    @objc func handleJoinGroup() {
        
        guard let groupId = group.groupId else {
            return
        }
        
        guard let currentUserId = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        let ref = FIRDatabase.database().reference().child("groups").child(groupId).child("groupMembers")
        
        let values: [String:Any] = [currentUserId: true]
        
        ref.updateChildValues(values){ (error, ref) in
            if error != nil {
                print(error as Any)
                return
            }
        }
        
        //store group id under user
        guard let userId = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        let userRef = FIRDatabase.database().reference().child("users").child(userId).child("groups")
        userRef.updateChildValues([groupId: true])
        
        let groupLogController = GroupLogController(collectionViewLayout: UICollectionViewFlowLayout())
        groupLogController.groupIdFromPreviousController = groupId
        navigationController?.pushViewController(groupLogController, animated: true)
    }
}
