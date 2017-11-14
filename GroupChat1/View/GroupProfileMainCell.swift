//
//  GroupProfileMainCell.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 10/12/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit
import Firebase

class GroupProfileMainCell: UICollectionViewCell {
    
    var onImageViewButtonTapped : (() -> Void)? = nil
    
    let cellView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.green.main
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let groupImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "default_camera")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 42
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    //because I was lazy
    lazy var groupImageViewBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = UIColor.clear
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.sizeToFit()
        btn.addTarget(self, action: #selector(handleGroupImageBtn), for: .touchUpInside)
        btn.layer.cornerRadius = 39
        return btn
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Sample text for now"
        label.font = UIFont.systemFont(ofSize: 22)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let groupDescriptionTextView: UITextView = {
        let tv = UITextView()
        tv.text = "Click to Edit Info"
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.backgroundColor = UIColor.clear
        tv.textColor = UIColor.white
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.sizeToFit()
        return tv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(cellView)
        cellView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        cellView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        cellView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        cellView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        
        cellView.addSubview(groupImageView)
        groupImageView.leftAnchor.constraint(equalTo: cellView.leftAnchor, constant: 8).isActive = true
        groupImageView.centerYAnchor.constraint(equalTo: cellView.centerYAnchor, constant: 5).isActive = true
        groupImageView.widthAnchor.constraint(equalToConstant: 78).isActive = true
        groupImageView.heightAnchor.constraint(equalToConstant: 78).isActive = true
        
        cellView.addSubview(groupImageViewBtn)
        groupImageViewBtn.leftAnchor.constraint(equalTo: groupImageView.leftAnchor).isActive = true
        groupImageViewBtn.centerYAnchor.constraint(equalTo: groupImageView.centerYAnchor).isActive = true
        groupImageViewBtn.widthAnchor.constraint(equalTo: groupImageView.widthAnchor).isActive = true
        groupImageViewBtn.heightAnchor.constraint(equalTo: groupImageView.heightAnchor).isActive = true
        
        cellView.addSubview(titleLabel)
        titleLabel.leftAnchor.constraint(equalTo: groupImageView.rightAnchor, constant: 8).isActive = true
        titleLabel.topAnchor.constraint(equalTo: groupImageView.topAnchor, constant: -5).isActive = true
        
        cellView.addSubview(groupDescriptionTextView)
        groupDescriptionTextView.leftAnchor.constraint(equalTo: titleLabel.leftAnchor, constant: -3).isActive = true
        groupDescriptionTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        groupDescriptionTextView.widthAnchor.constraint(equalToConstant: 270).isActive = true
        groupDescriptionTextView.heightAnchor.constraint(equalToConstant: 75).isActive = true
        
    }
    
    @objc private func handleGroupImageBtn() {
        if let onImageViewButtonTapped = self.onImageViewButtonTapped {
            onImageViewButtonTapped()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
