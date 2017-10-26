//
//  NewGroupController.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 9/27/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit
import Firebase

class NewGroupController: UIViewController, UITextViewDelegate {
    
    var keyboardHeight: CGFloat?
    
    let groupImageBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.blue.button
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 60; //rounded button
        view.layer.masksToBounds = true;
        return view
    }()
    
    lazy var groupImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "default_camera")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 0.5
        
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectGroupImageView)))
        imageView.isUserInteractionEnabled = true
        
        return imageView
    }()
    
    let groupNameInputViewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5; //rounded button
        view.layer.masksToBounds = true;
        return view
    }()
    
    let descriptionInputViewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5; //rounded button
        view.layer.masksToBounds = true;
        return view
    }()
    
    let tagsInputViewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5; 
        view.layer.masksToBounds = true;
        return view
    }()
    
    let groupNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Group Name"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    let groupDescriptionTextView: UITextView = {
        let tv = UITextView()
        tv.text = "Group Description"
        tv.textColor = UIColor(r: 199, g: 199, b: 205)
        tv.font = UIFont(name: ".SFUIText", size: 17)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    let tagsTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Tags (separate with commas)"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    lazy var createNewGroupButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.blue.button
        button.setTitle("Create", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        button.addTarget(self, action: #selector(handleCreateNewGroupButton), for: .touchUpInside)
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        groupDescriptionTextView.delegate = self
        
        view.backgroundColor = UIColor.blue.main
        
        view.addSubview(groupImageBackground)
        view.addSubview(groupNameInputViewContainer)
        view.addSubview(descriptionInputViewContainer)
        view.addSubview(tagsInputViewContainer)
        view.addSubview(createNewGroupButton)
        
        setupGroupImageView()
        setupGroupNameInputContainerView()
        setupDescriptionInputViewContainer()
        setupTagsInputViewContainer()
        setupCreateNewGroupButton()
        
        navigationController?.navigationBar.barTintColor = UIColor.blue.main
        navigationController?.navigationBar.tintColor = UIColor.white
        
        NotificationCenter.default.addObserver(self, selector: #selector(NewGroupController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NewGroupController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        canHideKeyboardByTappingOutsideOfTextFields()
    }
    
    var groupImageViewHeightAnchor: NSLayoutConstraint?
    var groupImageViewWidthAnchor: NSLayoutConstraint?
    
    private func setupGroupImageView() {
        
        groupImageBackground.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        groupImageBackground.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        groupImageBackground.widthAnchor.constraint(equalToConstant: 120).isActive = true
        groupImageBackground.heightAnchor.constraint(equalToConstant: 120).isActive = true
        
        groupImageBackground.addSubview(groupImageView)
        groupImageView.centerXAnchor.constraint(equalTo: groupImageBackground.centerXAnchor).isActive = true
        groupImageView.topAnchor.constraint(equalTo: groupImageBackground.topAnchor, constant: 10).isActive = true
        groupImageViewWidthAnchor = groupImageView.widthAnchor.constraint(equalToConstant: 90)
        groupImageViewWidthAnchor?.isActive = true
        groupImageViewHeightAnchor = groupImageView.heightAnchor.constraint(equalToConstant: 90)
        groupImageViewHeightAnchor?.isActive = true
    }
    
    private func setupGroupNameInputContainerView() {
        groupNameInputViewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        groupNameInputViewContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 250).isActive = true
        groupNameInputViewContainer.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        groupNameInputViewContainer.heightAnchor.constraint(equalToConstant: 50).isActive = true;
        
        groupNameInputViewContainer.addSubview(groupNameTextField)
        groupNameTextField.leftAnchor.constraint(equalTo: groupNameInputViewContainer.leftAnchor, constant: 12).isActive = true
        groupNameTextField.topAnchor.constraint(equalTo: groupNameInputViewContainer.topAnchor).isActive = true
        groupNameTextField.widthAnchor.constraint(equalTo: groupNameInputViewContainer.widthAnchor).isActive = true
        groupNameTextField.heightAnchor.constraint(equalTo: groupNameInputViewContainer.heightAnchor).isActive = true
    }
    
    private func setupDescriptionInputViewContainer() {
        
        descriptionInputViewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        descriptionInputViewContainer.topAnchor.constraint(equalTo: groupNameInputViewContainer.bottomAnchor, constant: 12).isActive = true
        descriptionInputViewContainer.widthAnchor.constraint(equalTo: groupNameInputViewContainer.widthAnchor).isActive = true
        descriptionInputViewContainer.heightAnchor.constraint(equalToConstant: 150).isActive = true;
        
        descriptionInputViewContainer.addSubview(groupDescriptionTextView)
        groupDescriptionTextView.leftAnchor.constraint(equalTo: descriptionInputViewContainer.leftAnchor, constant: 8).isActive = true
        groupDescriptionTextView.topAnchor.constraint(equalTo: descriptionInputViewContainer.topAnchor).isActive = true
        groupDescriptionTextView.widthAnchor.constraint(equalTo: descriptionInputViewContainer.widthAnchor, constant: -12).isActive = true
        groupDescriptionTextView.heightAnchor.constraint(equalTo: descriptionInputViewContainer.heightAnchor).isActive = true
        
    }
    
    private func setupTagsInputViewContainer() {
        
        tagsInputViewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tagsInputViewContainer.topAnchor.constraint(equalTo: descriptionInputViewContainer.bottomAnchor, constant: 12).isActive = true
        tagsInputViewContainer.widthAnchor.constraint(equalTo: descriptionInputViewContainer.widthAnchor).isActive = true
        tagsInputViewContainer.heightAnchor.constraint(equalTo: groupNameInputViewContainer.heightAnchor).isActive = true;
        
        tagsInputViewContainer.addSubview(tagsTextField)
        tagsTextField.leftAnchor.constraint(equalTo: descriptionInputViewContainer.leftAnchor, constant: 12).isActive = true
        tagsTextField.topAnchor.constraint(equalTo: tagsInputViewContainer.topAnchor).isActive = true
        tagsTextField.widthAnchor.constraint(equalTo: tagsInputViewContainer.widthAnchor).isActive = true
        tagsTextField.heightAnchor.constraint(equalTo: tagsInputViewContainer.heightAnchor).isActive = true
    }
    
    private func setupCreateNewGroupButton() {
        createNewGroupButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        createNewGroupButton.topAnchor.constraint(equalTo: tagsInputViewContainer.bottomAnchor, constant: 12).isActive = true
        createNewGroupButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        createNewGroupButton.widthAnchor.constraint(equalTo: tagsInputViewContainer.widthAnchor).isActive = true
        
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor(r: 199, g: 199, b: 205) {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Group Description"
            textView.textColor = UIColor(r: 199, g: 199, b: 205)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
