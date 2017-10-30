//
//  ProfileSegmentedControlCell.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 10/12/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit

class ProfileSegmentedControlCell: UICollectionViewCell {
    
    var onGroupLabelTapped : (() -> Void)? = nil
    var onMessagesLabelTapped : (() -> Void)? = nil
    
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(r: 131, g: 143, b: 147)//UIColor(r: 186, g: 200, b: 204)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var firstButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Groups", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        btn.setTitleColor(UIColor.green.main, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handleFirstBtn), for: .touchUpInside)
        return btn
    }()
    
    let firstSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.green.main
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = false
        return view
    }()
    
    lazy var secondButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Messages", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handleSecondBtn), for: .touchUpInside)
        return btn
    }()
    
    let secondSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.green.main
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(containerView)
        containerView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        containerView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        
        containerView.addSubview(firstButton)
        firstButton.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        firstButton.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        firstButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        firstButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 1/2).isActive = true
        
        containerView.addSubview(firstSeparatorView)
        firstSeparatorView.leftAnchor.constraint(equalTo: firstButton.leftAnchor).isActive = true
        firstSeparatorView.bottomAnchor.constraint(equalTo: firstButton.bottomAnchor).isActive = true
        firstSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        firstSeparatorView.widthAnchor.constraint(equalTo: firstButton.widthAnchor).isActive = true
        
        containerView.addSubview(secondButton)
        secondButton.leftAnchor.constraint(equalTo: firstButton.rightAnchor).isActive = true
        secondButton.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        secondButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        secondButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 1/2).isActive = true
        
        containerView.addSubview(secondSeparatorView)
        secondSeparatorView.leftAnchor.constraint(equalTo: secondButton.leftAnchor).isActive = true
        secondSeparatorView.bottomAnchor.constraint(equalTo: secondButton.bottomAnchor).isActive = true
        secondSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        secondSeparatorView.widthAnchor.constraint(equalTo: secondButton.widthAnchor).isActive = true
        
    }
    
    @objc func handleFirstBtn() {
        if let onGroupLabelTapped = self.onGroupLabelTapped {
            onGroupLabelTapped()
        }
        firstButton.setTitleColor(UIColor.green.main, for: .normal)
        secondButton.setTitleColor(UIColor.white, for: .normal)
        firstSeparatorView.isHidden = false
        secondSeparatorView.isHidden = true
    }
    
    @objc func handleSecondBtn() {
        if let onMessagesLabelTapped = self.onMessagesLabelTapped {
            onMessagesLabelTapped()
        }
        secondButton.setTitleColor(UIColor.green.main, for: .normal)
        firstButton.setTitleColor(UIColor.white, for: .normal)
        secondSeparatorView.isHidden = false
        firstSeparatorView.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
