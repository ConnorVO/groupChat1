//
//  ChatMessageCell.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 10/6/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit

class ChatMessageCell: UICollectionViewCell {
    
    var onUsernameBtnTapped : (() -> Void)? = nil
    var onGroupOwnerMenuBtnTapped: (() -> Void)? = nil
    
    let cellView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
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
        imageView.layer.cornerRadius = 31
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    lazy var usernameBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("loading...", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.sizeToFit()
        btn.addTarget(self, action: #selector(handleUsernameBtn), for: .touchUpInside)
        btn.isUserInteractionEnabled = false
        return btn
    }()
    
    let messageTextLabel: InsetLabelBottom = {
        let label = InsetLabelBottom()
        label.text = "loading..."
        label.font = UIFont.systemFont(ofSize: 14)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        return label
    }()
    
    let timestampSeparator: UILabel = {
        let label = UILabel()
        label.text = "."
        label.font = UIFont.systemFont(ofSize: 20)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        return label
    }()
    
    let timestampLabel: UILabel = {
        let label = UILabel()
        label.text = "11:45pm"
        label.font = UIFont.systemFont(ofSize: 14)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        return label
    }()
    
    let groupLabel: UILabel = {
        let label = UILabel()
        label.text = "in First Group: Connor's Group"
        label.font = UIFont.systemFont(ofSize: 14)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        label.isHidden = true
        return label
    }()
    
    let messageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.isHidden = true
        return imageView
    }()
    
    lazy var groupOwnerMenuBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("+", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.sizeToFit()
        btn.addTarget(self, action: #selector(handleGroupOwnerMenuBtn), for: .touchUpInside)
        return btn
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(cellView)
        cellView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        cellView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        cellView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        cellView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        cellView.addSubview(cellSeparatorView)
        cellSeparatorView.leftAnchor.constraint(equalTo: cellView.leftAnchor).isActive = true
        cellSeparatorView.topAnchor.constraint(equalTo: cellView.bottomAnchor).isActive = true
        cellSeparatorView.widthAnchor.constraint(equalTo: cellView.widthAnchor).isActive = true
        cellSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        cellView.addSubview(profileImageView)
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.topAnchor.constraint(equalTo: cellView.topAnchor).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 62).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 62).isActive = true
        
        cellView.addSubview(usernameBtn)
        usernameBtn.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        usernameBtn.topAnchor.constraint(equalTo: cellView.topAnchor, constant: -8).isActive = true
        
        cellView.addSubview(messageTextLabel)
        messageTextLabel.leftAnchor.constraint(equalTo: usernameBtn.leftAnchor).isActive = true
        messageTextLabel.topAnchor.constraint(equalTo: usernameBtn.bottomAnchor).isActive = true
        messageTextLabel.widthAnchor.constraint(equalToConstant: 250).isActive = true
        
        cellView.addSubview(timestampSeparator)
        timestampSeparator.leftAnchor.constraint(equalTo: usernameBtn.rightAnchor, constant: 4).isActive = true
        timestampSeparator.bottomAnchor.constraint(equalTo: usernameBtn.centerYAnchor, constant: 6).isActive = true
        
        cellView.addSubview(timestampLabel)
        timestampLabel.leftAnchor.constraint(equalTo: timestampSeparator.rightAnchor, constant: 4).isActive = true
        timestampLabel.centerYAnchor.constraint(equalTo: usernameBtn.centerYAnchor).isActive = true
        
        cellView.addSubview(groupLabel)
        groupLabel.leftAnchor.constraint(equalTo: usernameBtn.rightAnchor, constant: 4).isActive = true
        groupLabel.bottomAnchor.constraint(equalTo: usernameBtn.bottomAnchor, constant: -6).isActive = true
        
        cellView.addSubview(messageImageView)
        messageImageView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        messageImageView.topAnchor.constraint(equalTo: usernameBtn.bottomAnchor).isActive = true
        messageImageView.widthAnchor.constraint(equalTo: cellView.widthAnchor, constant: -86).isActive = true
        messageImageView.heightAnchor.constraint(equalTo: cellView.heightAnchor, constant: -66).isActive = true
        
        cellView.addSubview(groupOwnerMenuBtn)
        groupOwnerMenuBtn.rightAnchor.constraint(equalTo: cellView.rightAnchor, constant: -8).isActive = true
        groupOwnerMenuBtn.centerYAnchor.constraint(equalTo: usernameBtn.centerYAnchor, constant: -4).isActive = true
        
    }
    
    @objc private func handleUsernameBtn() {
        if let onUsernameBtnTapped = self.onUsernameBtnTapped {
            onUsernameBtnTapped()
        }
    }
    
    @objc private func handleGroupOwnerMenuBtn() {
        if let onGroupOwnerMenuBtnTapped = self.onGroupOwnerMenuBtnTapped {
            print("called")
            onGroupOwnerMenuBtnTapped()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


