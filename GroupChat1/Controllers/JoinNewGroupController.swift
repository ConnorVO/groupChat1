//
//  JoinNewGroupController.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 10/3/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit
import Firebase

class JoinNewGroupController: UIViewController {
    var group = Group()
    
    let groupImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "default_camera")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 60
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    let titleAndDescriptionView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "sample Text"
        label.font = UIFont.systemFont(ofSize: 14)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Sample text for now"
        label.font = UIFont.systemFont(ofSize: 14)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var joinGroupButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.blue.button
        button.setTitle("Join Group", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        button.addTarget(self, action: #selector(handleJoinGroup), for: .touchUpInside)
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.green.main
        
        view.addSubview(groupImageView)
        view.addSubview(titleAndDescriptionView)
        view.addSubview(joinGroupButton)
        
        setupGroupImageView()
        setupTitleAndDescriptionView()
        setupJoinGroupButton()
        
        populateGroupInfo()
        checkIfUserIsInGroup()
    }
    
    private func setupGroupImageView() {
        groupImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        groupImageView.bottomAnchor.constraint(equalTo: titleAndDescriptionView.topAnchor, constant: -12).isActive = true
        groupImageView.widthAnchor.constraint(equalToConstant: 120).isActive = true
        groupImageView.heightAnchor.constraint(equalToConstant: 120).isActive = true
    }
    
    var titleAndDescriptionViewHeightAnchor: NSLayoutConstraint?
    
    private func setupTitleAndDescriptionView() {
        titleAndDescriptionView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        titleAndDescriptionView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        titleAndDescriptionView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -48).isActive = true
        titleAndDescriptionViewHeightAnchor = titleAndDescriptionView.heightAnchor.constraint(equalToConstant: 150)
        titleAndDescriptionViewHeightAnchor?.isActive = true
        
        titleAndDescriptionView.addSubview(titleLabel)
        titleLabel.centerXAnchor.constraint(equalTo: titleAndDescriptionView.centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: titleAndDescriptionView.topAnchor).isActive = true
        titleLabel.widthAnchor.constraint(equalTo: titleAndDescriptionView.widthAnchor).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: (titleAndDescriptionViewHeightAnchor?.constant)! / 3).isActive = true
        
        titleAndDescriptionView.addSubview(descriptionLabel)
        descriptionLabel.centerXAnchor.constraint(equalTo: titleLabel.centerXAnchor).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        descriptionLabel.widthAnchor.constraint(equalTo: titleLabel.widthAnchor).isActive = true
        descriptionLabel.heightAnchor.constraint(equalToConstant: (titleAndDescriptionViewHeightAnchor?.constant)! * (2/3)).isActive = true
    }
    
    private func setupJoinGroupButton() {
        joinGroupButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        joinGroupButton.topAnchor.constraint(equalTo: titleAndDescriptionView.bottomAnchor).isActive = true
        joinGroupButton.widthAnchor.constraint(equalTo: titleAndDescriptionView.widthAnchor).isActive = true
        joinGroupButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    private func populateGroupInfo() {
        
        guard let groupName = group.groupName else {
            return
        }
        
        guard let groupDescription = group.groupDescription else {
            return
        }
        
        guard let groupImageUrl = group.groupImageUrl else {
            return
        }
        
        titleLabel.text = groupName
        descriptionLabel.text = groupDescription
        groupImageView.loadImageUsingCacheWithUrlString(urlString: groupImageUrl)
    }
    
    private func checkIfUserIsInGroup() {
        guard let currentUserId = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        guard let groupId = group.groupId else {
            return
        }
        
        let ref = FIRDatabase.database().reference().child("users").child(currentUserId).child("groups")
        ref.observe(.childAdded, with: { (snapshot) in
            
            if snapshot.key == groupId {
                self.joinGroupButton.backgroundColor = UIColor.green.main
                self.joinGroupButton.titleLabel?.text = "Joined"
            }
        })
    }
}
