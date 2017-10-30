//
//  HomePageController.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 9/25/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit
import Firebase

class HomePageController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
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
            print("Error getting uid from db")
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
        loginController.HomePageController = self //makes HomePageController not nil when calling self.HomePageController?.fetchUserAndSetupNavBarTitle from LoginController + Handlers
        
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
        cell.joinButton.setTitle("joined", for: .normal)
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
        
        //remove user from group and group from user
        FIRDatabase.database().reference().child("groups").child(groupId).child("groupMembers").child(currentUserId).removeValue()
        FIRDatabase.database().reference().child("users").child(currentUserId).child("groups").child(groupId).removeValue()
        
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
        
        return CGSize(width: UIScreen.main.bounds.width, height: 80)
        //Below is used for Apple recommended keyboard
        //return CGSize(width: view.frame.width, height: height)
    }
    
}

