//
//  UserProfileMainCell.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 10/9/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit
import Firebase

class UserProfileMainCell: UICollectionViewCell, UITextViewDelegate {
    
    var onImageViewButtonTapped : (() -> Void)? = nil
    
    let cellView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.green.main
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let cellSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "home_icon")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 42
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    //because I was lazy
    lazy var profileImageViewBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = UIColor.clear
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.sizeToFit()
        btn.addTarget(self, action: #selector(handleProfileImageBtn), for: .touchUpInside)
        btn.layer.cornerRadius = 42
        return btn
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Sample text for now"
        label.font = UIFont.systemFont(ofSize: 22)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        return label
    }()
    
    let userDescriptionTextView: UITextView = {
        let tv = UITextView()
        tv.text = "Click to Edit Info"
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.backgroundColor = UIColor.clear
        tv.textColor = UIColor.white
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.sizeToFit()
        return tv
    }()
    
    /*lazy var editButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("edit", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.setTitleColor(UIColor.lightGray, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.sizeToFit()
        btn.addTarget(self, action: #selector(handleEditBtn), for: .touchUpInside)
        return btn
    }()*/
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        userDescriptionTextView.delegate = self
        
        addSubview(cellView)
        cellView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        cellView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        cellView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        cellView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        
        cellView.addSubview(cellSeparatorView)
        cellSeparatorView.centerXAnchor.constraint(equalTo: cellView.centerXAnchor).isActive = true
        cellSeparatorView.topAnchor.constraint(equalTo: cellView.bottomAnchor).isActive = true
        cellSeparatorView.widthAnchor.constraint(equalTo: cellView.widthAnchor).isActive = true
        cellSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        cellView.addSubview(profileImageView)
        profileImageView.leftAnchor.constraint(equalTo: cellView.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: cellView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 84).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 84).isActive = true
        
        cellView.addSubview(usernameLabel)
        usernameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 24).isActive = true
        usernameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor).isActive = true
        usernameLabel.widthAnchor.constraint(equalToConstant: 150).isActive = true
        
        cellView.addSubview(userDescriptionTextView)
        userDescriptionTextView.leftAnchor.constraint(equalTo: usernameLabel.leftAnchor, constant: -3).isActive = true
        userDescriptionTextView.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor).isActive = true
        userDescriptionTextView.widthAnchor.constraint(equalToConstant: 250).isActive = true
        userDescriptionTextView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        /*cellView.addSubview(editButton)
        editButton.rightAnchor.constraint(equalTo: cellView.rightAnchor, constant: -8).isActive = true
        editButton.topAnchor.constraint(equalTo: cellView.topAnchor, constant: 4).isActive = true*/
        
        cellView.addSubview(profileImageViewBtn)
        profileImageViewBtn.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        profileImageViewBtn.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        profileImageViewBtn.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        profileImageViewBtn.widthAnchor.constraint(equalTo: profileImageView.widthAnchor).isActive = true
    }
    
    @objc private func handleProfileImageBtn() {
        if let onImageViewButtonTapped = self.onImageViewButtonTapped {
            onImageViewButtonTapped()
        }
    }
    
    var previousDescription: String?
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        previousDescription = userDescriptionTextView.text
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if userDescriptionTextView.text != previousDescription {
            guard let currentUserUid = FIRAuth.auth()?.currentUser?.uid else {
                return
            }
            let ref = FIRDatabase.database().reference().child("users").child(currentUserUid)
            ref.updateChildValues(["userDescription" : userDescriptionTextView.text])
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
