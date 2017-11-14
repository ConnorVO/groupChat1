//
//  GroupLogController.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 10/5/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit
import Firebase
import OneSignal
import Alamofire

class GroupLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.placeholder = "Enter Message"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    let chatMessageCellId = "messagesCellId"
    let groupProfileMainCellId = "groupProfileMainCellId"
    let chatSegmentedControlCellId = "chatSegmentedControlCellId"
    
    var groupIdFromPreviousController = "set by previous controller"
    var messageFromPreviousController: Message? = nil
    var messageIdFromPreviousController: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupKeyboardObserver()
        
        collectionView?.contentInset = UIEdgeInsetsMake(8, 0, 8, 0)
        collectionView?.backgroundColor = UIColor.white
        collectionView?.alwaysBounceVertical = true
        
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: chatMessageCellId)
        collectionView?.register(GroupProfileMainCell.self, forCellWithReuseIdentifier: groupProfileMainCellId)
        collectionView?.register(ChatSegmentedControlCell.self, forCellWithReuseIdentifier: chatSegmentedControlCellId)
        
        //use this for cooler interactive keyboard (not apple's documented ish)
        collectionView?.keyboardDismissMode = .interactive
        
        //maybe move to viewDidAppear?
        observeMessages { (messageIds) in
            self.checkIfUserCameFromAMessage()
        }
        
        observePinnedMessages()
        
        checkForPinnedMessage()
        
        //remove white space between collection view and navigation bar
        collectionView?.contentInset = UIEdgeInsetsMake(-10, 0, 0, 0)
    
    }
    
    var pinnedMessages = [Message]()
    private func observePinnedMessages() {
        let pinnedMessageRef = FIRDatabase.database().reference().child("groups").child(groupIdFromPreviousController).child("starredMessages")
        pinnedMessageRef.observe(.childAdded, with: { (snapshot) in
            let messageId = snapshot.key
            let messagesRef = FIRDatabase.database().reference().child("all-messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    let message = Message(dictionary: dictionary)
                    message.messageId = snapshot.key
                    self.pinnedMessages.append(message)
                }
            }, withCancel: nil)
        }, withCancel: nil)
    }
    
    var pinnedMessageView = PinnedMessageView()
    private func checkForPinnedMessage() {
        
        guard let currentUserUid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        let ref = FIRDatabase.database().reference().child("groups").child(groupIdFromPreviousController).child("starredMessages").queryLimited(toLast: 1)
        ref.observeSingleEvent(of: .childAdded, with: { (snapshot) in
            
            let messageId = snapshot.key
            guard let messagePinnedTimestamp = (snapshot.value as? Int) else {
                return
            }
            
            let latestUserTimestampRef = FIRDatabase.database().reference().child("users").child(currentUserUid).child("timestampOfLastVisit")
            latestUserTimestampRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                guard let userLastVisitTimestamp = (snapshot.value as? Int) else {
                    return
                }
                
                if messagePinnedTimestamp > userLastVisitTimestamp {
                    self.setupPinnedMessageView(withMessageId: messageId)
                }
                
            }, withCancel: nil)
            
        }, withCancel: nil)
        
    }
    
    private func setupPinnedMessageView(withMessageId messageId: String) {
        pinnedMessageView = PinnedMessageView(frame: CGRect(x: 0, y: (navigationController?.navigationBar.frame.size.height)! + 20, width: self.view.bounds.width, height: 40))
        self.view.addSubview(pinnedMessageView)
        
        pinnedMessageView.onCellBtnTapped = {
            
            guard let currentUserUid = FIRAuth.auth()?.currentUser?.uid else {
                return
            }
            
            let currentTimestamp = Int(NSDate().timeIntervalSince1970)
            let userRef = FIRDatabase.database().reference().child("users").child(currentUserUid)
            userRef.updateChildValues(["timestampOfLastVisit" : currentTimestamp])
            
            let groupRef = FIRDatabase.database().reference().child("groups").child(self.groupIdFromPreviousController).child("starredMessages")
            groupRef.updateChildValues([messageId : currentTimestamp])
            
            self.handlePinnedMessageViewTapped(withMessageId: messageId)
        }
    }
    
    private func handlePinnedMessageViewTapped(withMessageId messageId: String) {
        guard let pinnedMessage: Message = messages.first(where: { $0.messageId == messageId }) else {
            return
        }
        
        guard var pinnedMessageIndex = messages.index(of: pinnedMessage) else {
            return
        }
        
        pinnedMessageIndex = pinnedMessageIndex > 0 ? pinnedMessageIndex - 1 : 0
        
        let indexPath = IndexPath(item: pinnedMessageIndex, section: 2)
        collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
        
        pinnedMessageView.removeFromSuperview()
    }
    
    private func checkIfUserCameFromAMessage() {
        
        if let messageId = messageIdFromPreviousController {
            guard let index = self.messageIds.index(of: messageId) else {
                return
            }
            
            let indexPath = IndexPath(item: index - 1, section: 2)
            collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
            self.messageIdFromPreviousController = nil
        }
    }
    
    func setupKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
    
    @objc func handleKeyboardDidShow() {
        if messages.count > 0 {
            let indexPath = IndexPath(item: messages.count - 1, section: 2)
            if indexPath.row < collectionView!.numberOfItems(inSection: 2) {
                collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
            }
        }
    }
    
    lazy var inputContainerView: UIView = {
        var height: CGFloat = 50
        if UIDevice().userInterfaceIdiom == .phone {
            //iphone X - This allows it to cover tab bar like it is supposed to
            if UIScreen.main.nativeBounds.height == 2436 {
                height = 85
            }
        }
        
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: height)
        containerView.backgroundColor = UIColor.white
        
        let uploadImageView = UIImageView()
        uploadImageView.image = UIImage(named: "image_icon")
        uploadImageView.isUserInteractionEnabled = true
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectImageTap)))
        containerView.addSubview(uploadImageView)
        
        uploadImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 4).isActive = true
        uploadImageView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        let sendButton = UIButton(type: .system) //type: .system gives down state
        sendButton.setTitle("Send", for: .normal)
        sendButton.setTitleColor(UIColor.green.main, for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        containerView.addSubview(sendButton)
        
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        
        containerView.addSubview(self.inputTextField)
        
        self.inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 8).isActive = true
        self.inputTextField.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        self.inputTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.bottomAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        return containerView
    }()
    
    @IBAction func imageTapped(_ sender: UITapGestureRecognizer) {
        let imageView = sender.view as! UIImageView
        let newImageView = UIImageView(image: imageView.image)
        newImageView.frame = UIScreen.main.bounds
        newImageView.backgroundColor = .black
        newImageView.contentMode = .scaleAspectFit
        newImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage))
        newImageView.addGestureRecognizer(tap)
        self.view.addSubview(newImageView)
        self.navigationController?.isNavigationBarHidden = true
        self.tabBarController?.tabBar.isHidden = true
    }
    
    @objc func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
        self.navigationController?.isNavigationBarHidden = false
        self.tabBarController?.tabBar.isHidden = false
        sender.view?.removeFromSuperview()
    }
    
    @objc func handleSelectImageTap() {
        
        isNewGroupProfileImage = false
        
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.delegate = self
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            
            if isNewGroupProfileImage {
                uploadNewGroupImageToFirebase(withImage: selectedImage)
            } else {
                uploadToFirebase(withImage: selectedImage)
            }
            
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func uploadToFirebase(withImage image: UIImage) {
        let imageName = NSUUID().uuidString
        let ref = FIRStorage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            ref.put(uploadData, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print("Message Image Error: ", error as Any)
                    return
                }
                
                if let imageURL = metadata?.downloadURL()?.absoluteString {
                    self.sendMessage(withImageURL: imageURL, image: image)
                }
                
            })
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    //these next three funcs/variables are used for custom interactive keyboard
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    var messages = [Message]()
    var messageIds = [String]()
    var finalArr = [Dictionary<String, Any>]()
    
    private func observeMessages(completionHandler: @escaping ([String]) -> ()) {
   
        let groupId = groupIdFromPreviousController
        
        let groupMessagesRef = FIRDatabase.database().reference().child("groups").child(groupId).child("messages")
        groupMessagesRef.observe(.childAdded, with: { (snapshot) in
          
            let messageId = snapshot.key
            
            let messagesRef = FIRDatabase.database().reference().child("all-messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    let message = Message(dictionary: dictionary)
                    message.messageId = snapshot.key
                    self.messages.append(message)
                    self.messageIds.append(messageId)
                    
                    self.fetchUser(withMessage: message) { user, message in
                        
                        var dict = [String: Any]()
                        dict["user"] = user
                        dict["message"] = message
                        self.finalArr.append(dict)
                        
                        self.finalArr.sort(by: { (item1, item2) -> Bool in
                            let timestamp1 = (item1["message"] as! Message).timestamp
                            let timestamp2 = (item2["message"] as! Message).timestamp
                            return (timestamp1?.intValue)! < (timestamp2?.intValue)!
                        })
                        
                        completionHandler(self.messageIds)
                    }
                    
                    DispatchQueue.main.async {
                        //scroll to the last index
                        self.collectionView?.reloadData()
                        
                        let indexPath = IndexPath(item: self.messages.count - 1, section: 2)
                        self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                    }
                }
                
            }, withCancel: nil)
            
        }, withCancel: nil)

    }
    
    @objc func handleSend() {
        guard let inputText = inputTextField.text else {
            print("input text is nil")
            return
        }
        
        if (inputText == "") {
            print("invalid inpuText")
            return
        }
        
        let properties = ["text": inputText]
        
        sendMessage(withProperties: properties as [String : AnyObject])
    }
    
    private func sendMessage(withImageURL imageURL: String, image: UIImage) {
        let properties = ["imageURL": imageURL, "imageHeight": image.size.height, "imageWidth": image.size.width] as [String : Any]
        sendMessage(withProperties: properties as [String : AnyObject])
    }
    
    private func sendMessage(withProperties properties: [String: AnyObject]) {
        let ref = FIRDatabase.database().reference().child("all-messages")
        let childRef = ref.childByAutoId() //allows you to store list of child nodes (messages in this case)
        
        let groupId = groupIdFromPreviousController
        let fromId = FIRAuth.auth()!.currentUser!.uid
        let timestamp = Int(NSDate().timeIntervalSince1970)
        
        var values: [String: Any] = ["groupId": groupId, "fromId": fromId, "timestamp": timestamp, "isStarred": false]
        
        //key $0, value $1
        properties.forEach { (arg: (key: String, value: AnyObject)) in
            
            let (key, value) = arg
            values[key] = value
        }
        
        //firebase fan-out to reference only a users messages (not all messages)
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error as Any)
                return
            }
            
            //clear input text field when message is sent
            self.inputTextField.text = nil
            
            let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId)
            
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId: 1])
            
            let groupUserMessegasRef = FIRDatabase.database().reference().child("groups-messages").child(groupId).child(fromId)
            groupUserMessegasRef.updateChildValues([messageId: 1])
            
            let groupAllMessagesRef = FIRDatabase.database().reference().child("groups").child(groupId).child("messages")
            groupAllMessagesRef.updateChildValues([messageId: 1])
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section != 2 {
            return 1
        } else if activeSegment == 1 {
            return messages.count
        } else {
            return pinnedMessages.count
        }
    }
    
    var activeSegment = 1
    var groupTitle = String()
    var pinnedUsers = [User]()
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: groupProfileMainCellId, for: indexPath) as! GroupProfileMainCell
            
            let groupRef = FIRDatabase.database().reference().child("groups").child(groupIdFromPreviousController)
            groupRef.observeSingleEvent(of: .value, with: { (snapshot) in
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    cell.groupImageView.loadImageUsingCacheWithUrlString(urlString: dictionary["groupImageUrl"] as! String)
                    cell.titleLabel.text = dictionary["groupName"] as? String
                    self.groupTitle = (dictionary["groupName"] as? String)!
                    cell.groupDescriptionTextView.text = dictionary["groupDescription"] as? String
                }
            }, withCancel: nil)
            
            guard let currentUserUid = FIRAuth.auth()?.currentUser?.uid else {
                return cell
            }
            
            getGroupCreatorUid(completionHandler: { (response) in
                let groupCreatorUid = response
                
                if currentUserUid != groupCreatorUid {
                    cell.groupImageViewBtn.isUserInteractionEnabled = false
                    cell.groupDescriptionTextView.isUserInteractionEnabled = false
                }
                
                cell.onImageViewButtonTapped = {
                    self.handleProfileImageViewBtnTapped()
                }
            })
            
            cell.groupDescriptionTextView.delegate = self
            
            return cell
            
        } else if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: chatSegmentedControlCellId, for: indexPath) as! ChatSegmentedControlCell
            
            cell.onStarredLabelTapped = {
                if self.activeSegment != 2 {
                    self.activeSegment = 2
                    self.attemptReloadOfCollection()
                }
            }
            
            cell.onMessagesLabelTapped = {
                if self.activeSegment != 1 {
                    self.activeSegment = 1
                    self.attemptReloadOfCollection()
                }
            }
            
            return cell
        } else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: chatMessageCellId, for: indexPath) as! ChatMessageCell
            
            if activeSegment == 1 {
            
            if finalArr.count > 0 && finalArr.count > indexPath.row {
                
                guard let uid = (finalArr[indexPath.row]["user"] as! User).id, let username = (finalArr[indexPath.row]["user"] as! User).name, let profileImageUrl = (finalArr[indexPath.row]["user"] as! User).profileImageUrl, let timestamp = (finalArr[indexPath.row]["message"] as! Message).timestamp, let messageId = (finalArr[indexPath.row]["message"] as! Message).messageId, let isStarred = (finalArr[indexPath.row]["message"] as! Message).isStarred, let fromId = (finalArr[indexPath.row]["message"] as! Message).fromId else {
                    return cell
                }
                
                if isStarred {
                    cell.starredSeparator.isHidden = false
                    cell.starredLabel.isHidden = false
                } else {
                    cell.starredSeparator.isHidden = true
                    cell.starredLabel.isHidden = true
                }
                
                var messageText2 = String()
                if let messageImageURL = (finalArr[indexPath.row]["message"] as! Message).imageURL {
                    cell.messageImageView.loadImageUsingCacheWithUrlString(urlString: messageImageURL)
                    cell.messageImageView.isHidden = false
                    cell.messageTextView.isHidden = true
                    let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
                    cell.messageImageView.addGestureRecognizer(tap)
                } else {
                    //in here because for whatever reason if I move outside it prevents images from loading
                    guard let messageText = (finalArr[indexPath.row]["message"] as! Message).text else {
                        return cell
                    }
                    messageText2 = messageText
                    cell.messageTextView.text = messageText
                    cell.messageImageView.isHidden = true
                    cell.messageTextView.isHidden = false
                }
                
                cell.usernameBtn.setTitle(username, for: .normal)
                cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
                cell.groupLabel.isHidden = true
                cell.usernameBtn.isUserInteractionEnabled = true
                
                cell.onUsernameBtnTapped = {
                    self.handleUsernameButtonTap(uid: uid, indexPath: indexPath)
                }
                
                guard let currentUserUid = FIRAuth.auth()?.currentUser?.uid else {
                    return cell
                }
                
                if uid == currentUserUid {
                    cell.usernameBtn.setTitleColor(UIColor.green.darker, for: .normal)
                } else {
                    cell.usernameBtn.setTitleColor(UIColor.black, for: .normal)
                }
                
                getGroupCreatorUid(completionHandler: { (response) in
                    let groupCreatorUid = response
                    var isGroupCreator = true
                    cell.groupOwnerMenuBtn.isHidden = false
                    
                    if currentUserUid != groupCreatorUid {
                        isGroupCreator = false
                    }
                    
                    if currentUserUid != fromId && currentUserUid != groupCreatorUid {
                        cell.groupOwnerMenuBtn.isHidden = true
                    }
                    
                    cell.onGroupOwnerMenuBtnTapped = {
                        self.handleGroupOwnerMenuBtnTapped(withMessageText: messageText2, groupTitle: self.groupTitle, messageId: messageId, groupId: self.groupIdFromPreviousController, isGroupCreator: isGroupCreator, messageFromId: fromId, indexPathRow: indexPath.row)
                    }
                })
                
                setupMessageTime(cell: cell, timestamp: timestamp)
            }
            
            return cell
            } else {
                
                guard let messageText = pinnedMessages[indexPath.row].text, let uid = pinnedMessages[indexPath.row].fromId, let timestamp = pinnedMessages[indexPath.row].timestamp, let messageId = pinnedMessages[indexPath.row].messageId else {
                    return cell
                }
                
                let pinnedUser = User()
                let userRef = FIRDatabase.database().reference().child("users").child(uid)
                userRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    if let dictionary = snapshot.value as? [String: AnyObject] {
                        pinnedUser.name = dictionary["name"] as? String
                        pinnedUser.profileImageUrl = dictionary["profileImageURL"] as? String
                        
                        if let username = pinnedUser.name, let userProfileImageUrl = pinnedUser.profileImageUrl {
                            cell.usernameBtn.setTitle(username, for: .normal)
                            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: userProfileImageUrl)
                        }
                        //self.pinnedUsers.append(pinnedUser)
                        
                        self.attemptReloadOfCollection()
                    }
                }, withCancel: nil)
                
                cell.messageTextView.text = messageText
                cell.starredLabel.isHidden = false
                cell.starredSeparator.isHidden = false
                cell.groupOwnerMenuBtn.isHidden = true
                
                setupMessageTime(cell: cell, timestamp: timestamp)
                
                return cell
            }
        }
    }
    
    private func handleGroupOwnerMenuBtnTapped(withMessageText messageText: String, groupTitle: String, messageId: String, groupId: String, isGroupCreator: Bool, messageFromId: String, indexPathRow: Int) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
            // ...
        }
        alertController.addAction(cancelAction)
        
        if isGroupCreator {
        
            let pinActionWithoutNotify = UIAlertAction(title: "Pin Message", style: .default) { action in
                // ...
                //TODO
                /*self.getOneSignalIdsOfGroupMembers(completionHandler: { (users) in
                    self.sendNotification(to: users, withMessageText: messageText, withGroupName: groupTitle)
                })*/
                
                let currentTimestamp = Int(NSDate().timeIntervalSince1970)
                
                let groupRef = FIRDatabase.database().reference().child("groups").child(self.groupIdFromPreviousController).child("starredMessages")
                groupRef.updateChildValues([messageId : currentTimestamp])
                
                let messageRef = FIRDatabase.database().reference().child("all-messages").child(messageId)
                messageRef.updateChildValues(["isStarred" : true])
                
            }
            alertController.addAction(pinActionWithoutNotify)
            
            let pinAndNotifyAction = UIAlertAction(title: "Pin Message and Notify Group", style: .default) { action in
                // ...
                
                let currentTimestamp = Int(NSDate().timeIntervalSince1970)
                
                let groupRef = FIRDatabase.database().reference().child("groups").child(self.groupIdFromPreviousController).child("starredMessages")
                groupRef.updateChildValues([messageId : currentTimestamp])
                
                let messageRef = FIRDatabase.database().reference().child("all-messages").child(messageId)
                messageRef.updateChildValues(["isStarred" : true])
                
                OneSignal.getTags({ (tags) in
                    print(Array(tags!.values))
                })
            }
           /* let parameters: Parameters = [
            [
                "app_id": "5eb5a37e-b458-11e3-ac11-000c2940e62c",
                "filters": [
                    ["field": "tag", "key": "level", "relation": "=", "value": "10"],
                ],
                "data": ["foo": "bar"],
                "contents": ["en": "English Message"]
            ]
            ]
            
            let json = [
                "filters": [
                    "field": "tag", "key": "uid", "relation": "exists"
                ],
                "contents": ["en": "First Message"], // Required unless "content_available": true or "template_id" is set
                "headings": ["en": "Notification Title"],
                "subtitle": ["en": "An English Subtitle"],
                // If want to open a url with in-app browser
                //"url": "https://google.com",
                // If you want to deep link and pass a URL to your webview, use "data" parameter and use the key in the AppDelegate's notificationOpenedBlock
                "data": ["OpenURL": "https://imgur.com"],
                "ios_badgeType": "Increase",
                "ios_badgeCount": 1
                ] as [String : Any]
           
            // All three of these calls are equivalent
            //Alamofire.request("https://onesignal.com/api/v1/notifications", method: .post, parameters: parameters)*/
            
            alertController.addAction(pinAndNotifyAction)
        }
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { action in
            FIRDatabase.database().reference().child("groups").child(self.groupIdFromPreviousController).child("messages").child(messageId).removeValue()
            
            FIRDatabase.database().reference().child("groups").child(self.groupIdFromPreviousController).child("starredMessages").child(messageId).removeValue()
            
            FIRDatabase.database().reference().child("all-messages").child(messageId).removeValue()
            
            FIRDatabase.database().reference().child("user-messages").child(messageFromId).child(messageId).removeValue()
            
            FIRDatabase.database().reference().child("groups-messages").child(self.groupIdFromPreviousController).child(messageFromId).child(messageId).removeValue()
            
            if let message = self.finalArr[indexPathRow]["message"] as? Message {
                
                if self.messages.contains(message) {
                    guard let messageIndex = self.messages.index(of: message) else {
                        return
                    }
                    self.messages.remove(at: messageIndex)
                }
                
                if self.pinnedMessages.contains(message) {
                    guard let messageIndex = self.pinnedMessages.index(of: message) else {
                        return
                    }
                    self.pinnedMessages.remove(at: messageIndex)
                }
                
                if self.messageIds.contains(messageFromId) {
                    guard let messageIndex = self.messageIds.index(of: messageFromId) else {
                        return
                    }
                    self.messageIds.remove(at: messageIndex)
                }
                
                //self.attemptReloadOfCollection()
                //NOT WORKING YET - NOT UPDATING PROPERLY without having to leave and come back
                
            }
        }
        alertController.addAction(deleteAction)
        
        self.present(alertController, animated: true) {
            // ...
        }
    }
    
    var oneSignalIdsOfGroupMembers = [String]()
    
    private func getOneSignalIdsOfGroupMembers(completionHandler: @escaping ([String]) -> ()) {
        
        let ref = FIRDatabase.database().reference().child("groups").child(groupIdFromPreviousController).child("groupMemberOneSignalIds")
        ref.observe(.value, with: { (snapshot) in
            for child in snapshot.children.allObjects as! [FIRDataSnapshot] {
                self.oneSignalIdsOfGroupMembers.append(child.key)
            }
            completionHandler(self.oneSignalIdsOfGroupMembers)
        }, withCancel: nil)
    }
    
    var previousDescription: String?
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        previousDescription = textView.text
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text != previousDescription {
            let ref = FIRDatabase.database().reference().child("groups").child(groupIdFromPreviousController)
            ref.updateChildValues(["groupDescription" : textView.text])
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
         
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
         print(updatedText.count)
        return updatedText.count <= 90
    }
    
    private func getGroupCreatorUid(completionHandler: @escaping (String) -> ()) {
        var groupCreatorUid: String?
        let ref = FIRDatabase.database().reference().child("groups").child(groupIdFromPreviousController).child("groupCreator")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            groupCreatorUid = snapshot.value as? String
            guard let unwrappedGroupCreatorUid = groupCreatorUid else {
                return
            }
            completionHandler(unwrappedGroupCreatorUid)
        }, withCancel: nil)
    }
    
    var isNewGroupProfileImage = false
    
    private func handleProfileImageViewBtnTapped() {
        
        isNewGroupProfileImage = true
        
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
    }
    
    private func uploadNewGroupImageToFirebase(withImage image: UIImage) {
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
                
                if let groupImageURL = metaData?.downloadURL()?.absoluteString {
                    let values = ["groupImageUrl": groupImageURL]
                    let ref = FIRDatabase.database().reference()
                    let userRef = ref.child("groups").child(self.groupIdFromPreviousController)
                    
                    userRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
                        if error != nil {
                            print(error as Any)
                            return
                        }
                        
                       // self.user.profileImageUrl = values["groupImageURL"]
                        
                        self.collectionView?.reloadData()
                        self.dismiss(animated: true, completion: nil)
                    })
                }
            })
        }
    }
    
    private func handleUsernameButtonTap(uid: String, indexPath: IndexPath) {
        if uid == FIRAuth.auth()?.currentUser?.uid {

            Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(switchToProfileTabCont), userInfo: nil, repeats: false)
    
        } else {
            let usernameController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
            usernameController.activeSegment = 1
            usernameController.userUid = uid
            navigationController?.pushViewController(usernameController, animated: true)
        }
    }
    
    @objc private func switchToProfileTabCont(){
        tabBarController!.selectedIndex = 2
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
    
    var users = [User]()
    
    private func fetchUser(withMessage message: Message, completionHandler: @escaping (User, Message) -> ()) {
        
        guard let messageUserId = message.fromId else {
            return
        }
        FIRDatabase.database().reference().child("users").child(messageUserId ).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: Any] {
                let user = User()
                user.name = dictionary["username"] as? String
                user.profileImageUrl = dictionary["profileImageURL"] as? String
                user.id = snapshot.key
                completionHandler(user, message)
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
        
        /* self.messages = Array(self.messageDictionary.values)
         self.messages.sort(by: { (message1, message2) -> Bool in
         guard let timestamp1 = message1.timestamp else {
         print("timestamp1 is nil")
         return true
         }
         guard let timestamp2 = message2.timestamp else {
         print("timestamp2 is nil")
         return true
         }
         return timestamp1.intValue > timestamp2.intValue
         
         })*/
        
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: UIScreen.main.bounds.width, height: 120)
        } else if indexPath.section == 1 {
            return CGSize(width: UIScreen.main.bounds.width, height: 40)
        } else {
            var height: CGFloat = 80
            
            let message = messages[indexPath.row]
            
            if let text = message.text {
                height = estimateFrameForText(text: text).height + 10 //add 20 for a little spacing
            } else if let imageHeight = message.imageHeight?.floatValue, let imageWidth = message.imageWidth?.floatValue {
                //h1 = h2 / w2 * w1
                let screenWidth: Float = Float(UIScreen.main.bounds.width)
                height = CGFloat(imageHeight / imageWidth * screenWidth) + 80
                
            }
            
            if height < 50 {
                return CGSize(width: UIScreen.main.bounds.width, height: 80) //one line height = 29.0937
            } else if height < 80 {
                return CGSize(width: UIScreen.main.bounds.width, height: 95) //two line height = 67.28125
            } else if height < 100{
                return CGSize(width: UIScreen.main.bounds.width, height: 110) //three line height = 86.375
            } else {
                return CGSize(width: UIScreen.main.bounds.width, height: height)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 2 {
            return UIEdgeInsetsMake(10, 0, 0, 0)
        } else {
            return UIEdgeInsets.zero
        }
    }
    
    private func estimateFrameForText(text: String) -> CGRect {
        //width is similar to bubble view width and height is arbitrarilly large
        let size = CGSize(width: 200, height: 1000)
        //idk why you have to set options like this
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    func sendNotification(to users: [String], withMessageText messageText: String, withGroupName: String) {
        // See the Create notification REST API POST call for a list of all possible options: https://documentation.onesignal.com/reference#create-notification
        // NOTE: You can only use include_player_ids as a targeting parameter from your app. Other target options such as tags and included_segments require your OneSignal App REST API key which can only be used from your server.
        
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        let pushToken = status.subscriptionStatus.pushToken
        //let userId = status.subscriptionStatus.userId
        
        if pushToken != nil {
           // if messageText.extractURLs().count > 0 {
                let notificationContent = [
                    "include_player_ids": users,
                    "contents": ["en": messageText], // Required unless "content_available": true or "template_id" is set
                    "headings": ["en": groupTitle],
                    // "subtitle": ["en": "An English Subtitle"],
                    // If want to open a url with in-app browser
                    "url": "\(messageText.extractURLs()[0])",
                    // If you want to deep link and pass a URL to your webview, use "data" parameter and use the key in the AppDelegate's notificationOpenedBlock
                    //"data": ["OpenURL": "https://imgur.com"],
                    //"ios_attachments": ["id" : "https://www.t-nation.com/system/publishing/article_assets/4433/original/Bad-Butt.jpg?ts=1487365755"],
                    "ios_badgeType": "Increase",
                    "ios_badgeCount": 1
                    ] as [String : Any]
          /*  } *//*else {
                let notificationContent = [
                    "include_player_ids": users,
                    "contents": ["en": messageText], // Required unless "content_available": true or "template_id" is set
                    "headings": ["en": groupTitle],
                   // "subtitle": ["en": "An English Subtitle"],
                    // If want to open a url with in-app browser
                    //"url": "https://www.t-nation.com/system/publishing/article_assets/4433/original/Bad-Butt.jpg?ts=1487365755",
                    // If you want to deep link and pass a URL to your webview, use "data" parameter and use the key in the AppDelegate's notificationOpenedBlock
                    //"data": ["OpenURL": "https://imgur.com"],
                    //"ios_attachments": ["id" : "https://www.t-nation.com/system/publishing/article_assets/4433/original/Bad-Butt.jpg?ts=1487365755"],
                    "ios_badgeType": "Increase",
                    "ios_badgeCount": 1
                    ] as [String : Any]
            }*/
            OneSignal.postNotification(notificationContent)
        }
    }
    
    
}

public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}
