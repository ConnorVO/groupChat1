//
//  SearchForGroupsController.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 10/2/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit
import Firebase
import OneSignal

class SearchForGroupsController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(GroupCell.self, forCellWithReuseIdentifier: cellId)
        
        observeGroups()
        
        //fix spacing between top cell and nav bar
        collectionView?.contentInset = UIEdgeInsetsMake(5, 0, 0, 0)
        
        if #available(iOS 11.0, *) {
            navigationItem.title = "Search"
        } else {
            navigationItem.title = ""
        }
        
        setupSearchBar()
    }
    
    let searchController = UISearchController(searchResultsController: nil)
    lazy var searchBar:UISearchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 275, height: 20))
    
    private func setupSearchBar() {
        
        if #available(iOS 11.0, *) {
            searchController.searchResultsUpdater = self
            searchController.obscuresBackgroundDuringPresentation = false
            //searchController.searchBar.placeholder = "Search For Groups"
            navigationItem.searchController = searchController
        } else {
            searchBar.delegate = self
            searchBar.placeholder = "Search For Groups"
            searchBar.barStyle = UIBarStyle.blackTranslucent
            let leftNavBarButton = UIBarButtonItem(customView:searchBar)
            self.navigationItem.leftBarButtonItem = leftNavBarButton
            let cancelSearchBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(SearchForGroupsController.cancelBarButtonItemClicked))
            self.navigationItem.setRightBarButton(cancelSearchBarButtonItem, animated: true)
        }

        definesPresentationContext = true
    
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        //TODO: Search updates
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    var filteredGroups = [Group]()
    private func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        if #available(iOS 11.0, *) {
            return searchController.searchBar.text?.isEmpty ?? true
        } else {
            return searchBar.text?.isEmpty ?? true
        }
    }
    
    private func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredGroups = groups.filter({( group : Group) -> Bool in
            return (group.groupName?.lowercased().contains(searchText.lowercased()))!
        })
        
        collectionView?.reloadData()
    }
    
    private func isFiltering() -> Bool {
        if #available(iOS 11.0, *) {
            return searchController.isActive && !searchBarIsEmpty()
        } else {
            return searchBarisActive && !searchBarIsEmpty()
        }
    }
    
    var searchBarisActive = false
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBarisActive = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBarisActive = false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterContentForSearchText(searchBar.text!)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // closes the keyboard
        searchBar.resignFirstResponder()
    }
    
    @objc func cancelBarButtonItemClicked() {
        self.searchBarCancelButtonClicked(self.searchBar)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = true
        }
        self.collectionView?.reloadData()
    }
    
    var groups = [Group]()
    
    
    func observeGroups() {
        
        groups.removeAll()
        
        let allGroupsRef = FIRDatabase.database().reference().child("groups")
        allGroupsRef.observe(.childAdded, with: { (snapshot) in
                
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let group = Group()
                group.groupId = snapshot.key
                group.groupName = dictionary["groupName"] as? String
                group.groupDescription = dictionary["groupDescription"] as? String
                group.groupImageUrl = dictionary["groupImageUrl"] as? String
        
                self.groups.append(group)
                
                self.attemptReloadOfCollection()
                
                //scroll to the last index
                /*if (self.groups.count > 0) {
                    let indexPath = IndexPath(item: self.groups.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                } <--crashing */
            }
            
        }, withCancel: nil)

    }
    
    private func attemptReloadOfCollection() {
        //delays reload to allow firebase to correctly populate profile images
        //also prevents reloadTable from being called multiple times because all timers except the last one get invalidated before they get called
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadofCollection), userInfo: nil, repeats: false)
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
        if isFiltering() {
            return filteredGroups.count
        }
        
        return groups.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GroupCell

        let group: Group
        
        if isFiltering() {
            group = filteredGroups[indexPath.row]
        } else {
            group = groups[indexPath.row]
        }
        
        cell.titleLabel.text = group.groupName
        cell.descriptionLabel.text = group.groupDescription
        cell.cellGroupId = group.groupId!
        
        if let groupImageUrl = group.groupImageUrl {
            cell.groupImageView.loadImageUsingCacheWithUrlString(urlString: groupImageUrl)
        }
        
        cell.onJoinButtonTapped = {
            self.joinButtonTappedHandler(indexPath: indexPath, cell: cell)
        }
        
        checkIfUserIsInGroup(cell: cell, indexPath: indexPath)
        
        return cell
    }
    
    var joinedGroups = [String]()
    private func checkIfUserIsInGroup(cell: GroupCell, indexPath: IndexPath) {
        
        joinedGroups.removeAll()
        cell.joinButton.setTitleColor(UIColor.red, for: .normal)
        cell.joinButton.setTitle("\u{2713}", for: .normal)
        
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
                cell.joinButton.setTitle("\u{2713}", for: .normal)
            } else {
                cell.joinButton.setTitleColor(UIColor.red, for: .normal)
                cell.joinButton.setTitle("+", for: .normal)
            }
            
        })
    }
    
    var homePageController: HomePageController?
    var userProfileController: UserProfileController?
    
    private func joinButtonTappedHandler(indexPath: IndexPath, cell: GroupCell) {
        
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
        
        //probably not safest way to do this?
        if joinedGroups.contains(groupId) {
            //remove user from group and group from user
            FIRDatabase.database().reference().child("groups").child(groupId).child("memberCount").observeSingleEvent(of: .value, with: { (snapshot) in
                if let numberOfMembers = snapshot.value as? Int {
                    FIRDatabase.database().reference().child("groups").child(groupId).updateChildValues(["memberCount" : numberOfMembers - 1])
                }
            }, withCancel: nil)
            
            FIRDatabase.database().reference().child("groups").child(groupId).child("groupMembers").child(currentUserId).removeValue()
            FIRDatabase.database().reference().child("users").child(currentUserId).child("groups").child(groupId).removeValue()
            
            FIRDatabase.database().reference().child("groups").child(groupId).child("groupMemberOneSignalIds").child(oneSignalUserID).removeValue()
            
            joinedGroups.remove(at: joinedGroups.index(of: groupId)!)
            
            cell.joinButton.setTitle("+", for: .normal)
            cell.joinButton.setTitleColor(UIColor.red, for: .normal)
            
        } else {
            
            FIRDatabase.database().reference().child("groups").child(groupId).child("memberCount").observeSingleEvent(of: .value, with: { (snapshot) in
                if let numberOfMembers = snapshot.value as? Int {
                    FIRDatabase.database().reference().child("groups").child(groupId).updateChildValues(["memberCount" : numberOfMembers + 1])
                }
            }, withCancel: nil)
            
            let ref = FIRDatabase.database().reference().child("groups").child(groupId).child("groupMembers")
            
            let values: [String:Any] = [currentUserId: true]
            
            ref.updateChildValues(values){ (error, ref) in
                if error != nil {
                    print(error as Any)
                    return
                }
            }
            
            let userRef = FIRDatabase.database().reference().child("users").child(currentUserId).child("groups")
            userRef.updateChildValues([groupId: true])
            
            let oneSignalGroupRef = FIRDatabase.database().reference().child("groups").child(groupId).child("groupMemberOneSignalIds")
            oneSignalGroupRef.updateChildValues([oneSignalUserID: true])
        
            createKeyForOneSignalTagDictionary(withGroupId: groupId)
            
            cell.joinButton.setTitle("\u{2713}", for: .normal)
            cell.joinButton.setTitleColor(UIColor.green.main, for: .normal)
        }
        
        //observeGroups()
    }
    
    private func createKeyForOneSignalTagDictionary(withGroupId groupId: String) {
        let randomKey = RandomAlphanumericKey.randomAlphanumericString(length: 8)
        
        setTagForOneSignalTagDictionary(withKey: randomKey, withValue: groupId)
    }
    
    private func setTagForOneSignalTagDictionary(withKey key: String, withValue value: String) {
       
        OneSignal.sendTag(key, value: value, onSuccess: { (tags) in
        }) { (err) in
            print(err as Any)
        }
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
    }
    
}
