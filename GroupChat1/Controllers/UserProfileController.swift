//
//  UserProfileCollection.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 10/9/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit
import Firebase

class UserProfileController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let userProfileMainCellId = "userProfileMainCellId"
    let userProfileGroupCellId = "userProfileGroupCellId"
    let profileSegmentedControlCellId = "profileSegmentedControlCellId"
    let chatMessageCellId = "chatMessageCellId"
    
    //from other controller
    var userUid:String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(UserProfileMainCell.self, forCellWithReuseIdentifier: userProfileMainCellId)
        collectionView?.register(GroupCell.self, forCellWithReuseIdentifier: userProfileGroupCellId)
        collectionView?.register(ProfileSegmentedControlCell.self, forCellWithReuseIdentifier: profileSegmentedControlCellId)
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: chatMessageCellId)
        
        getCurrentUserInfo()
        
        navigationItem.title = "Profile"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observeUserGroups()
        observeUserMessages()
    }
    
    let user = User()
    
    private func getCurrentUserInfo() {
        guard let userId = userUid else {
            return
        }
        
        let ref = FIRDatabase.database().reference().child("users").child(userId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                self.user.name = dictionary["username"] as? String
                self.user.profileImageUrl = dictionary["profileImageURL"] as? String
                self.user.groups = dictionary["groups"]?.allKeys as? [String]
                self.user.userDescription = dictionary["userDescription"] as? String
                
                self.attemptReloadOfCollection()
            }
        }, withCancel: nil)
        
    }
    
    //retrieving only a users groups using firebase fan-out
    private func observeUserGroups() {
        
        groups.removeAll()
        
        guard let uid = userUid else {
            return
        }
        
        let ref = FIRDatabase.database().reference().child("users").child(uid).child("groups")
        ref.observe(.childAdded, with: { (snapshot) in
            
            let groupId = snapshot.key
            
            self.fetchGroup(withGroupId: groupId)
            
        }, withCancel: nil)
        
    }
    
    var messages = [Message]()
    var messageIds = [String]()
    
    private func observeUserMessages() {
        
        messages.removeAll()
        
        guard let uid = userUid else {
            return
        }
        
        let ref = FIRDatabase.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            let messageId = snapshot.key
            
            let messageRef = FIRDatabase.database().reference().child("all-messages").child(messageId)
            messageRef.observeSingleEvent(of: .value, with: { (snapshot) in
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    let message = Message(dictionary: dictionary)
                    self.messages.append(message)
                    self.messageIds.append(snapshot.key)
                    self.attemptReloadOfCollection()
                }
            }, withCancel: nil)
        }, withCancel: nil)
    }
    
    
    
    var groups = [Group]()
    
    private func fetchGroup(withGroupId groupId: String) {
        let groupReference = FIRDatabase.database().reference().child("groups").child(groupId)
        
        groupReference.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let group = Group()
                group.groupId = snapshot.key
                group.groupName = dictionary["groupName"] as? String
                group.groupDescription = dictionary["groupDescription"] as? String
                group.groupImageUrl = dictionary["groupImageUrl"] as? String
                
                self.groups.append(group)
                
                self.attemptReloadOfCollection()
            }
        }, withCancel: nil)
    }
    
    private func attemptReloadOfCollection() {
        //delays reload to allow firebase to correctly populate profile images
        //also prevents reloadTable from being called multiple times because all timers except the last one get invalidated before they get called
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadofCollection), userInfo: nil, repeats: false)
    }
    
    var timer: Timer?
    
    @objc func handleReloadofCollection() {
    
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section != 2 {
            return 1
        } else if activeSegment == 1 {
            return groups.count
        } else {
            return messages.count
        }
    }
    
    var activeSegment = 1
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: userProfileMainCellId, for: indexPath) as! UserProfileMainCell
        
            if let username = user.name {
                cell.usernameLabel.text = username
            }
            
            if let userProfileImage = user.profileImageUrl {
                cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: userProfileImage)
            }
            
            if let userDescription = user.userDescription {
                cell.userDescriptionTextView.text = userDescription
            }
            
            guard let currentUserUid = FIRAuth.auth()?.currentUser?.uid else {
                return cell
            }
            
            if currentUserUid != userUid {
                cell.profileImageViewBtn.isUserInteractionEnabled = false
                cell.userDescriptionTextView.isUserInteractionEnabled = false
            }
            
            cell.onImageViewButtonTapped = {
                self.handleProfileImageViewBtnTapped()
            }
            
            return cell
        } else if indexPath.section == 1 {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: profileSegmentedControlCellId, for: indexPath) as! ProfileSegmentedControlCell
            
            cell.onMessagesLabelTapped = {
                if self.activeSegment != 2 {
                    self.activeSegment = 2
                    self.attemptReloadOfCollection()
                }
            }
            
            cell.onGroupLabelTapped = {
                if self.activeSegment != 1 {
                    self.activeSegment = 1
                    self.attemptReloadOfCollection()
                }
            }
            
            return cell
            
        } else {

            if activeSegment == 1 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: userProfileGroupCellId, for: indexPath) as! GroupCell
                
                if groups.count == 0 {
                    attemptReloadOfCollection()
                } else {
                    let group = groups[indexPath.row]
                   
                    cell.titleLabel.text = group.groupName
                    cell.descriptionLabel.text = group.groupDescription
                    
                    cell.onJoinButtonTapped = {
                        self.handleJoinButtonTap(cell: cell, indexPath: indexPath)
                    }
                    
                    if let groupImageUrl = group.groupImageUrl {
                        cell.groupImageView.loadImageUsingCacheWithUrlString(urlString: groupImageUrl)
                    }
                    
                    checkIfUserIsInGroup(cell: cell, indexPath: indexPath)
                }
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: chatMessageCellId, for: indexPath) as! ChatMessageCell
                cell.usernameBtn.setTitle(user.name, for: .normal)
                cell.messageTextLabel.text = messages[indexPath.row].text
                //cell.groupOwnerMenuBtn.isHidden = true
                guard let timestamp = messages[indexPath.row].timestamp else {
                    return cell
                }
                if let userProfileImageUrl = user.profileImageUrl {
                    cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: userProfileImageUrl)
                }
                setupMessageTime(cell: cell, timestamp: timestamp)
                
                if let groupId = messages[indexPath.row].groupId {
                    FIRDatabase.database().reference().child("groups").child(groupId).child("groupName").observeSingleEvent(of: .value, with: { (snapshot) in
                        let groupName = snapshot.value as? String
                        if let groupName = groupName {
                             cell.groupLabel.text = "in \(String(describing: groupName))"
                        }
                    }, withCancel: nil)
                    cell.groupLabel.isHidden = false
                }
                
                return cell
            }
        }
    }
    
    var joinedGroups = [String]()
    private func checkIfUserIsInGroup(cell: GroupCell, indexPath: IndexPath) {
        
        joinedGroups.removeAll()
        
        guard let currentUserId = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        guard let groupId = groups[indexPath.row].groupId else {
            return
        }
        
        let ref = FIRDatabase.database().reference().child("users").child(currentUserId).child("groups")
        ref.observe(.childAdded, with: { (snapshot) in
            
            if snapshot.key == groupId {
                self.joinedGroups.append(groupId)
            }
            
            if self.joinedGroups.contains(groupId) {
                cell.joinButton.setTitleColor(UIColor.green.main, for: .normal)
                cell.joinButton.setTitle("joined", for: .normal)
            } else {
                cell.joinButton.setTitleColor(UIColor.red, for: .normal)
                cell.joinButton.setTitle("join", for: .normal)
            }
            
        })
    }
    
    private func handleProfileImageViewBtnTapped() {
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadNewImageToFirebase(withImage: selectedImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    private func uploadNewImageToFirebase(withImage image: UIImage) {
        //generate unique name for each image
        let imageName = NSUUID().uuidString
        let storageRef = FIRStorage.storage().reference().child("profile_images").child("\(imageName).png")
        
        //safely unwrap profileImageView.image
        //compress profile image for worse quality but faster upload and smaller size
        if let uploadData = UIImageJPEGRepresentation(image, 0.1) {
            
            storageRef.put(uploadData, metadata: nil, completion: { (metaData, error) in
                
                if error != nil {
                    print("Image Storage Error: ", error as Any)
                    return
                }
                
                if let profileImageURL = metaData?.downloadURL()?.absoluteString {
                    let values = ["profileImageURL": profileImageURL]
                    let ref = FIRDatabase.database().reference()
                    guard let currentUserUid = FIRAuth.auth()?.currentUser?.uid else {
                        return
                    }
                    let userRef = ref.child("users").child(currentUserUid)
                    
                    userRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
                        if error != nil {
                            print(error as Any)
                            return
                        }
                     
                        self.user.profileImageUrl = values["profileImageURL"]
                        if let profileImageView = self.user.profileImageUrl {
                            let homePageController = HomePageController(collectionViewLayout: UICollectionViewFlowLayout())
                            homePageController.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageView)
                        }
                        
                        self.collectionView?.reloadData()
                        self.dismiss(animated: true, completion: nil)
                    })
                }
            })
        }
    }
    
    private func setupMessageTime(cell: ChatMessageCell, timestamp: NSNumber) {
        
        let messageTimestamp = Date(timeIntervalSince1970: timestamp.doubleValue)
        
        let dayDifference = Date().days(from: messageTimestamp)
        let hourDifference = Date().hours(from: messageTimestamp)
        let minuteDifference = Date().minutes(from: messageTimestamp)
        
        if minuteDifference < 60 {
            cell.timestampLabel.text = "\(minuteDifference)m"
        } else if hourDifference < 24 {
            cell.timestampLabel.text = "\(hourDifference)h"
        } else {
            cell.timestampLabel.text = "\(dayDifference)d"
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if activeSegment == 1 {
            if indexPath.section == 2 {
                let groupLogController = GroupLogController(collectionViewLayout: UICollectionViewFlowLayout())
                guard let groupId = groups[indexPath.row].groupId else {
                    return
                }
                groupLogController.groupIdFromPreviousController = groupId
                navigationController?.pushViewController(groupLogController, animated: true)
            }
        } else {
            if indexPath.section == 2 {
                guard let groupId = messages[indexPath.row].groupId else {
                    return
                }
                let groupLogController = GroupLogController(collectionViewLayout: UICollectionViewFlowLayout())
                groupLogController.groupIdFromPreviousController = groupId
                groupLogController.messageIdFromPreviousController = messageIds[indexPath.row]
                navigationController?.pushViewController(groupLogController, animated: true)
            }
        }
    }
    
    private func handleJoinButtonTap(cell: GroupCell, indexPath: IndexPath) {
        guard let groupId = groups[indexPath.row].groupId else {
            return
        }
        
        guard let currentUserId = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        //remove user from group and group from user
        FIRDatabase.database().reference().child("groups").child(groupId).child("groupMembers").child(currentUserId).removeValue()
        FIRDatabase.database().reference().child("users").child(currentUserId).child("groups").child(groupId).removeValue()
        
        observeUserGroups()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.section == 0 {
            return CGSize(width: UIScreen.main.bounds.width, height: 120)
        } else if indexPath.section == 1 {
            return CGSize(width: UIScreen.main.bounds.width, height: 40)
        } else {
            return CGSize(width: UIScreen.main.bounds.width, height: 80)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 2 {
            return UIEdgeInsetsMake(6, 0, 0, 0)
        } else {
            return UIEdgeInsets.zero
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
}
