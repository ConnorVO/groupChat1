//
//  PinnedMessageView.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 11/3/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit

class PinnedMessageView: UIView {
    
     var onCellBtnTapped : (() -> Void)? = nil
    
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.blue.main
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let textLabel: UILabel = {
        let label = UILabel()
        label.text = "(Name Here) has pinned a new message!"
        label.font = UIFont.systemFont(ofSize: 16)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.sizeToFit()
       // label.textAlignment = .center
        return label
    }()
    
    lazy var cellBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = UIColor.clear
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handleCellBtn), for: .touchUpInside)
        btn.isUserInteractionEnabled = true
        return btn
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(containerView)
        containerView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        containerView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        containerView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        
        containerView.addSubview(textLabel)
        textLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 10).isActive = true
        textLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        //textLabel.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        textLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -20).isActive = true
        
        containerView.addSubview(cellBtn)
        cellBtn.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        cellBtn.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        cellBtn.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        cellBtn.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handleCellBtn() {
        if let onCellBtnTapped = self.onCellBtnTapped {
            onCellBtnTapped()
        }
    }
    
}
