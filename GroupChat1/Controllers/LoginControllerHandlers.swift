//
//  LoginControllerHandlers.swift
//  Group Chat App Try 1
//
//  Created by Connor Van Ooyen on 9/25/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit
import Firebase

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func handleLoginRegister() {
        if loginRegisterSegmentedControl.selectedSegmentIndex == 0 {
            handleLogin()
        } else {
            handleRegister()
        }
    }
    
    func handleLogin() {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            print("Email and/or password not valid")
            return
        }
        
         FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
         
             if error != nil {
                print("Login Error: ", error as Any)
             }
         
             self.messagesController?.fetchUserandSetupNavBarTitle()
             self.dismiss(animated: true, completion: nil)
         
         })
    }
    
    func handleRegister() {
        
        guard let email = emailTextField.text, let password = passwordTextField.text, let username = usernameTextField.text, let profileImage = profileImageView.image else {
            print("Email and/or password not valid")
            return
        }
        
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_")
        if (username.rangeOfCharacter(from: allowedCharacters.inverted) != nil || username == "") {
            print("invalid")
            return
        }
        
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user: FIRUser?, error) in
             if error != nil {
                print(error as Any)
             }
         
             guard let uid = user?.uid else {
                print("Could not set user uid")
                return
             }
            
             //generate unique name for each image
             let imageName = NSUUID().uuidString
             let storageRef = FIRStorage.storage().reference().child("profile_images").child("\(imageName).png")
            
             //safely unwrap profileImageView.image
             //compress profile image for worse quality but faster upload and smaller size
             if let uploadData = UIImageJPEGRepresentation(profileImage, 0.1) {
                
                 storageRef.put(uploadData, metadata: nil, completion: { (metaData, error) in
         
                     if error != nil {
                        print("Image Storage Error: ", error as Any)
                        return
                     }
                    
                    if let profileImageURL = metaData?.downloadURL()?.absoluteString {
                        let values = ["username": username, "email": email, "profileImageURL": profileImageURL, "searchUsername": username.lowercased()]
                        self.checkIfUsernameisAvailable(uid: uid, values: values as [String:AnyObject])
                    }
         
                 })
            }
         })
    }
    
    private func checkIfUsernameisAvailable(uid: String, values: [String: AnyObject]) {
        guard let lowercasedUsername = usernameTextField.text?.lowercased() else {
            return
        }
        
        let usernameRef = FIRDatabase.database().reference().child("usernames")
        let checkForExistingUsernameRef = FIRDatabase.database().reference().child("usernames").queryOrderedByKey().queryEqual(toValue: lowercasedUsername)
        checkForExistingUsernameRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if snapshot.exists() {
                print("Username already taken")
            } else {
                self.registerUserIntoDatabase(withUID: uid, values: values)
                usernameRef.updateChildValues([lowercasedUsername: lowercasedUsername])
            }
        }, withCancel: nil )
    }
    
    private func registerUserIntoDatabase(withUID uid: String, values: [String: AnyObject]) {
         let ref = FIRDatabase.database().reference()
         let userRef = ref.child("users").child(uid)
        
         userRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print(error as Any)
                return
            }
     
     
             let user = User()
             user.email = values["email"] as? String
             user.name = values["username"] as? String
             user.profileImageUrl = values["profileImageURL"] as? String
             self.messagesController?.setupNavBarWithUser(user: user)
            
             self.dismiss(animated: true, completion: nil)
         })
     }
    
    @objc func handleSelectProfileImageView() {
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
            profileImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func handleLoginRegisterChange() {
        let title = loginRegisterSegmentedControl.titleForSegment(at: loginRegisterSegmentedControl.selectedSegmentIndex)
        
        loginRegisterButton.setTitle(title, for: .normal)
        
        //change input container height
        inputsContainerViewHeightAnchor?.constant = loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 100 : 150
        
        //remove/add name field
        usernameTextFieldHeightAnchor?.isActive = false
        usernameTextFieldHeightAnchor = usernameTextField.heightAnchor.constraint(equalTo: inputsViewContainer.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 0 : 1/3)
        usernameTextFieldHeightAnchor?.isActive = true
        
        //change email height
        emailTextFieldHeightAnchor?.isActive = false
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsViewContainer.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        //change password height
        passwordTextFieldHeightAnchor?.isActive = false
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputsViewContainer.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        passwordTextFieldHeightAnchor?.isActive = true
        
        if loginRegisterSegmentedControl.selectedSegmentIndex == 0 {
            profileImageView.isHidden = true
        } else {
            profileImageView.isHidden = false
        }
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
                self.view.frame.origin.y -= keyboardHeight! / 2
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height == 0 ? CGFloat(256) : keyboardSize.height
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardHeight! / 2
            }
        }
    }
}


