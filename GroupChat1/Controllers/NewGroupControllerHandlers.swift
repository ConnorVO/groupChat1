//
//  NewGroupControllerHandlers.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 9/29/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit
import Firebase
import OneSignal

extension NewGroupController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func handleCancelNewGroup() {
        let homePageController = HomePageController()
        present(homePageController, animated: true, completion: nil)
    }
    
    @objc func handleCreateNewGroupButton() {
        guard let groupTagsText = tagsTextField.text else {
            return
        }
        
        guard let groupNameText = groupNameTextField.text else {
            return
        }
        
        guard let groupDescriptionText = groupDescriptionTextView.text else {
            return
        }
        
        guard let groupImage = groupImageView.image else {
            return
        }
        
        if (groupNameText != "" && groupDescriptionText != "" && groupDescriptionText != "Group Description" && groupTagsText != "") {
            let groupTagsArray = groupTagsText.components(separatedBy: ",") as [String]
            saveNewGroupInfoToDatabase(groupImage: groupImage, groupName: groupNameText, groupDescription: groupDescriptionText, groupTags: groupTagsArray)
            
            navigationController?.pushViewController(HomePageController(collectionViewLayout: UICollectionViewFlowLayout()), animated: true)
            
        } else {
            print("Tags or Group Name are empty")
        }
    }
    
    private func saveNewGroupInfoToDatabase(groupImage: UIImage, groupName: String, groupDescription: String, groupTags: [String]) {
        let ref = FIRDatabase.database().reference().child("groups")
        let childRef = ref.childByAutoId()
        
        //generate unique name for each image
        let imageName = NSUUID().uuidString
        let imageRef = FIRStorage.storage().reference().child("group_profile_images").child("\(imageName).png")
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        guard let oneSignalUserID = status.subscriptionStatus.userId else {
            return
        }
        
        if let uploadData = UIImageJPEGRepresentation(groupImage, 0.2) {
            imageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print("Message Image Error: ", error as Any)
                    return
                }
                
                guard let currentUserId = FIRAuth.auth()?.currentUser?.uid else {
                    return
                }
                
                let groupMembers: [String: Any] = [currentUserId: true]
                let oneSignalUserIds: [String: Any] = [oneSignalUserID: true]
                
                if let groupImageUrl = metadata?.downloadURL()?.absoluteString {
                    let values: [String: Any] = ["groupImageUrl": groupImageUrl, "groupName": groupName, "groupDescription": groupDescription, "groupMembers": groupMembers, "groupCreator": currentUserId, "groupMemberOneSignalIds": oneSignalUserIds, "memberCount": 1]
                    
                    childRef.updateChildValues(values){ (error, ref) in
                        if error != nil {
                            print(error as Any)
                            return
                        }
                    }
                    
                    for element in groupTags {
                        let ref = FIRDatabase.database().reference().child("all_group_tags")
                        let autoIdRef = ref.childByAutoId()
                        let value = [element.lowercased(): "1"]
                        autoIdRef.updateChildValues(value){ (error, ref) in
                            if error != nil {
                                print(error as Any)
                                return
                            }
                            let tagId = autoIdRef.key
                            let value = [tagId: "1"]
                            childRef.child("groupTags").updateChildValues(value, withCompletionBlock: { (err, ref) in
                                if error != nil {
                                    print(error as Any)
                                    return
                                }
                            })
                        }
                    }
                    
                    
                    guard let userId = FIRAuth.auth()?.currentUser?.uid else {
                        return
                    }
                    
                    //store group id under user
                    let groupId = childRef.key
                    
                    let userRef = FIRDatabase.database().reference().child("users").child(userId).child("groups")
                    userRef.updateChildValues([groupId: true]) { (error, ref) in
                        if error != nil {
                            print(error as Any)
                            return
                        }
                    }
                }
                
            })
        }
    }
    
    @objc func handleSelectGroupImageView() {
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
            groupImageView.image = selectedImage
            groupImageView.alpha = 1.0
            groupImageViewWidthAnchor?.constant = 120
            groupImageViewHeightAnchor?.constant = 120
            groupImageView.layer.cornerRadius = 60
            groupImageView.layer.masksToBounds = true
            groupImageBackground.backgroundColor = UIColor.clear
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func canHideKeyboardByTappingOutsideOfTextFields() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginController.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height == 0 ? CGFloat(256) : keyboardSize.height
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardHeight! / 1.5
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardHeight! / 1.5
            }
        }
    }
}
