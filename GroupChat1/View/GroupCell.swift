//
//  GroupCell.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 10/2/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit
import Firebase

class GroupCell: UICollectionViewCell {
    
    var onJoinButtonTapped : (() -> Void)? = nil
    var cellGroupId = ""
    
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
    
    let groupImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "home_icon")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 31
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let titleLabel: InsetLabelTop = {
        let label = InsetLabelTop()
        label.text = "Sample text for now"
        label.font = UIFont.systemFont(ofSize: 16)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.black
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let descriptionLabel: InsetLabelBottom = {
        let label = InsetLabelBottom()
        label.text = "Sample text for now"
        label.font = UIFont.systemFont(ofSize: 14)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var joinButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("\u{2713}", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        btn.setTitleColor(UIColor.red, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.sizeToFit()
        btn.addTarget(self, action: #selector(handleJoinBtn), for: .touchUpInside)
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
        
        cellView.addSubview(groupImageView)
        groupImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        groupImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -1).isActive = true
        groupImageView.heightAnchor.constraint(equalToConstant: 62).isActive = true
        groupImageView.widthAnchor.constraint(equalToConstant: 62).isActive = true
        
        cellView.addSubview(titleLabel)
        titleLabel.leftAnchor.constraint(equalTo: groupImageView.rightAnchor, constant: 8).isActive = true
        titleLabel.topAnchor.constraint(equalTo: cellView.topAnchor, constant: -10).isActive = true
        //titleLabel.widthAnchor.constraint(equalToConstant: 150).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        cellView.addSubview(descriptionLabel)
        descriptionLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8).isActive = true
        descriptionLabel.widthAnchor.constraint(equalToConstant: 250).isActive = true
        //descriptionLabel.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        cellView.addSubview(joinButton)
        joinButton.rightAnchor.constraint(equalTo: cellView.rightAnchor, constant: -12).isActive = true
        joinButton.centerYAnchor.constraint(equalTo: cellView.centerYAnchor).isActive = true
        joinButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handleJoinBtn() {
        if let onJoinButtonTapped = self.onJoinButtonTapped {
            onJoinButtonTapped()
        }
    }
}

