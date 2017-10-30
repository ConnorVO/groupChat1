//
//  SearchForGroupsController.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 10/2/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit
import Firebase

class SearchForGroupsController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(GroupCell.self, forCellWithReuseIdentifier: cellId)
        
        observeGroups()
        
        //fix spacing between top cell and nav bar
        collectionView?.contentInset = UIEdgeInsetsMake(5, 0, 0, 0)
        
        navigationItem.title = "Search"
        
        setupSearchBar()
    }
    
    let searchController = UISearchController(searchResultsController: nil)
    
    private func setupSearchBar() {
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search For Groups"
        navigationItem.searchController = searchController

        definesPresentationContext = true
    
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        //TODO: Search updates
        filterContentForSearchText(searchController.searchBar.text!)
        //print(searchController.searchBar.text!.lowercased())
    }
    
    var filteredGroups = [Group]()
    private func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    private func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredGroups = groups.filter({( group : Group) -> Bool in
            return (group.groupName?.lowercased().contains(searchText.lowercased()))!
        })
        
        collectionView?.reloadData()
    }
    
    private func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
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
            self.joinButtonTappedHandler(indexPath: indexPath)
        }
        
        checkIfUserIsInGroup(cell: cell, indexPath: indexPath)
        
        return cell
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
    
    private func joinButtonTappedHandler(indexPath: IndexPath) {
        
        guard let groupId = groups[indexPath.row].groupId else {
            return
        }
        
        guard let currentUserId = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        //probably not safest way to do this?
        if joinedGroups.contains(groupId) {
            //remove user from group and group from user
            FIRDatabase.database().reference().child("groups").child(groupId).child("groupMembers").child(currentUserId).removeValue()
            FIRDatabase.database().reference().child("users").child(currentUserId).child("groups").child(groupId).removeValue()
            joinedGroups.remove(at: joinedGroups.index(of: groupId)!)
        } else {
            
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
        }
        
        observeGroups()
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
    
    private func estimateFrameForText(text: String) -> CGRect {
        //width is similar to bubble view width and height is arbitrarilly large
        let size = CGSize(width: 200, height: 1000)
        //idk why you have to set options like this
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
}
