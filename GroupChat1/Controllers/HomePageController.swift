//
//  HomePageController.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 9/25/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit
import Firebase
import OneSignal

class HomePageController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, OSPermissionObserver, OSSubscriptionObserver{
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(GroupCell.self, forCellWithReuseIdentifier: cellId)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New Group", style: .plain, target: self, action: #selector(handleNewGroup))
        
        checkIfUserIsLoggedIn()
        
        //fix spacing between top cell and nav bar
        collectionView?.contentInset = UIEdgeInsetsMake(5, 0, 0, 0)
        
        if let uid = FIRAuth.auth()?.currentUser?.uid {
            OneSignal.sendTag("uid", value: uid)
        }
        
        oneSignalFromViewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = "Home"
        
        observeUserGroups()
    }
    
    private func checkIfUserIsLoggedIn() {
        
        if FIRAuth.auth()?.currentUser?.uid == nil {
            //run handleLogout after viewController is loaded
            //prevent Warning: Unbalanced calls to begin/end appearance transitions for
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
            fetchUserandSetupNavBarTitle()
        }
    }
    
    func fetchUserandSetupNavBarTitle() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        FIRDatabase.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                
                let user = User()
                user.name = dictionary["username"] as? String
                user.profileImageUrl = dictionary["profileImageURL"] as? String
                self.setupNavBarWithUser(user: user)
            }
            
        }, withCancel: nil)
    }
    
    let profileImageView = UIImageView()
    func setupNavBarWithUser(user: User) {
        groups.removeAll()
        collectionView?.reloadData()

        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(containerView)
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
       
        if let profileImageUrl = user.profileImageUrl {
            profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        containerView.addSubview(profileImageView)
        
        //ios 9 constraint anchors
        //need x,y,width,height anchors
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let nameLabel = UILabel()
        
        containerView.addSubview(nameLabel)
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        //need x,y,width,height anchors
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
        self.navigationItem.titleView = titleView
        
    }
    
    @objc func handleNewGroup() {
       // sendNotification()
        let newGroupController = NewGroupController()
        navigationController?.pushViewController(newGroupController, animated: true)
    }
    
    @objc func handleLogout() {
        
        //logout user
        do {
            try FIRAuth.auth()?.signOut()
        } catch let logoutError {
            print("Logout Error: ", logoutError)
        }
        
        let loginController = LoginController()
        loginController.homePageController = self //makes HomePageController not nil when calling self.HomePageController?.fetchUserAndSetupNavBarTitle from LoginController + Handlers
        
        present(loginController, animated: true, completion: nil)
    }
    
    //retrieving only a users groups using firebase fan-out
    func observeUserGroups() {
        
        groups.removeAll()
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        let ref = FIRDatabase.database().reference().child("users").child(uid).child("groups")
        ref.observe(.childAdded, with: { (snapshot) in
            
            let groupId = snapshot.key
            
            self.fetchGroup(withGroupId: groupId)
            
        }, withCancel: nil)
        
        //if there is only cell and I delete it (i.e. leave the group), then the above ref
        //doesn't get called so the data doesnt reload so I have to do it here
        self.collectionView?.reloadData()
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
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groups.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GroupCell
        
        let group = groups[indexPath.row]
        cell.titleLabel.text = group.groupName
        cell.descriptionLabel.text = group.groupDescription
        cell.joinButton.setTitle("\u{2713}", for: .normal)
        cell.joinButton.setTitleColor(UIColor.green.main, for: .normal)
        
        cell.onJoinButtonTapped = {
            self.handleJoinButtonTap(cell: cell, indexPath: indexPath)
        }
        
        if let groupImageUrl = group.groupImageUrl {
            cell.groupImageView.loadImageUsingCacheWithUrlString(urlString: groupImageUrl)
        }
    
        return cell
    }
    
    private func handleJoinButtonTap(cell: GroupCell, indexPath: IndexPath) {
        guard let groupId = groups[indexPath.row].groupId else {
            return
        }
        
        guard let currentUserId = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        guard let oneSignalUserID = status.subscriptionStatus.userId else {
            return
        }
        
        //remove user from group and group from user
        FIRDatabase.database().reference().child("groups").child(groupId).child("memberCount").observeSingleEvent(of: .value, with: { (snapshot) in
            if let numberOfMembers = snapshot.value as? Int {
                FIRDatabase.database().reference().child("groups").child(groupId).updateChildValues(["memberCount" : numberOfMembers - 1])
            }
        }, withCancel: nil)
        FIRDatabase.database().reference().child("groups").child(groupId).child("groupMembers").child(currentUserId).removeValue()
        FIRDatabase.database().reference().child("users").child(currentUserId).child("groups").child(groupId).removeValue()
    
        FIRDatabase.database().reference().child("groups").child(groupId).child("groupMemberOneSignalIds").child(oneSignalUserID).removeValue()
        
        observeUserGroups()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let groupLogController = GroupLogController(collectionViewLayout: UICollectionViewFlowLayout())
        guard let groupId = groups[indexPath.row].groupId else {
            return
        }
        groupLogController.groupIdFromPreviousController = groupId
        navigationController?.pushViewController(groupLogController, animated: true)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: UIScreen.main.bounds.width, height: 100)
        //Below is used for Apple recommended keyboard
        //return CGSize(width: view.frame.width, height: height)
    }
    
    //ONESIGNAL STUFF
    private func oneSignalFromViewDidLoad() {
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        let isSubscribed = status.subscriptionStatus.subscribed
        print(status)
        print(isSubscribed)
        
        /*if isSubscribed == true {
            allowNotificationsSwitch.isOn = true
            allowNotificationsSwitch.isUserInteractionEnabled = true
            registerForPushNotificationsButton.backgroundColor = UIColor.green
            registerForPushNotificationsButton.isUserInteractionEnabled = false
        }*/
        OneSignal.add(self as OSPermissionObserver)
        OneSignal.add(self as OSSubscriptionObserver)
    }
    
    func displaySettingsNotification() {
        let message = NSLocalizedString("Please turn on notifications by going to Settings > Notifications > Allow Notifications", comment: "Alert message when the user has denied access to the notifications")
        let alertController = UIAlertController(title: "OneSignal Example", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .`default`, handler: { action in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
            }
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func onOSPermissionChanged(_ stateChanges: OSPermissionStateChanges!) {
        if stateChanges.from.status == OSNotificationPermission.notDetermined {
            if stateChanges.to.status == OSNotificationPermission.authorized {
                /*registerForPushNotificationsButton.backgroundColor = UIColor.green
                registerForPushNotificationsButton.isUserInteractionEnabled = false
                allowNotificationsSwitch.isUserInteractionEnabled = true*/
            } else if stateChanges.to.status == OSNotificationPermission.denied {
                displaySettingsNotification()
            }
        } else if stateChanges.to.status == OSNotificationPermission.denied { // DENIED = NOT SUBSCRIBED
            /*registerForPushNotificationsButton.isUserInteractionEnabled = true
            allowNotificationsSwitch.isUserInteractionEnabled = false*/
        }
    }
    
    func onOSSubscriptionChanged(_ stateChanges: OSSubscriptionStateChanges!) {
        if stateChanges.from.subscribed && !stateChanges.to.subscribed { // NOT SUBSCRIBED != DENIED
            /*allowNotificationsSwitch.isOn = false
            setSubscriptionLabel.text = "Set Subscription OFF"
            registerForPushNotificationsButton.backgroundColor = UIColor.red*/
        } else if !stateChanges.from.subscribed && stateChanges.to.subscribed {
            /*allowNotificationsSwitch.isOn = true
            allowNotificationsSwitch.isUserInteractionEnabled = true
            setSubscriptionLabel.text = "Set Subscription ON"
            registerForPushNotificationsButton.backgroundColor = UIColor.green
            registerForPushNotificationsButton.isUserInteractionEnabled = false*/
        }
    }
    
    /*func registerForPushNotifications() {
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        let hasPrompted = status.permissionStatus.hasPrompted
        if hasPrompted == false {
            // Call when you want to prompt the user to accept push notifications.
            // Only call once and only if you set kOSSettingsKeyAutoPrompt in AppDelegate to false.
            OneSignal.promptForPushNotifications(userResponse: { accepted in
                if accepted == true {
                    print("User accepted notifications: \(accepted)")
                } else {
                    print("User accepted notifications: \(accepted)")
                }
            })
        } else {
            displaySettingsNotification()
        }
    }
    
    func getIds() {
        //getPermissionSubscriptionState
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        let hasPrompted = status.permissionStatus.hasPrompted
        print("hasPrompted = \(hasPrompted)")
        let userStatus = status.permissionStatus.status
        print("userStatus = \(userStatus)")
        let isSubscribed = status.subscriptionStatus.subscribed
        print("isSubscribed = \(isSubscribed)")
        let userSubscriptionSetting = status.subscriptionStatus.userSubscriptionSetting
        print("userSubscriptionSetting = \(userSubscriptionSetting)")
        let userID = status.subscriptionStatus.userId
        print("userID = \(userID)")
        let pushToken = status.subscriptionStatus.pushToken
        print("pushToken = \(pushToken)")
    }*/
    
    func sendNotification() {
        // See the Create notification REST API POST call for a list of all possible options: https://documentation.onesignal.com/reference#create-notification
        // NOTE: You can only use include_player_ids as a targeting parameter from your app. Other target options such as tags and included_segments require your OneSignal App REST API key which can only be used from your server.
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        let pushToken = status.subscriptionStatus.pushToken
        let userId = status.subscriptionStatus.userId
        
        if pushToken != nil {
            let message = "This is a notification's message or body"
            let notificationContent = [
                "include_player_ids": ["a1bf9ed9-0959-4c88-974b-5a829c1cdcc9"],
                "contents": ["en": message], // Required unless "content_available": true or "template_id" is set
                "headings": ["en": "Notification Title"],
                "subtitle": ["en": "An English Subtitle"],
                // If want to open a url with in-app browser
                "url": "https://google.com",
                // If you want to deep link and pass a URL to your webview, use "data" parameter and use the key in the AppDelegate's notificationOpenedBlock
                //"data": ["OpenURL": "https://imgur.com"],
                //"ios_attachments": ["id" : "https://cdn.pixabay.com/photo/2017/01/16/15/17/hot-air-balloons-1984308_1280.jpg"],
                "ios_badgeType": "Increase",
                "ios_badgeCount": 1
                ] as [String : Any]
            
            OneSignal.postNotification(notificationContent)
        }
    }
    
}

