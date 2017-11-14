//
//  CustomTabBarController.swift
//  GroupChat1
//
//  Created by Connor Van Ooyen on 10/2/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit
import Firebase

class CustomTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let homeController = HomePageController(collectionViewLayout: UICollectionViewFlowLayout())
        let homeNavigationController = UINavigationController(rootViewController: homeController)
        homeNavigationController.title = "Home"
        homeNavigationController.tabBarItem.image = UIImage(named: "home_icon")
        
        let searchController = SearchForGroupsController(collectionViewLayout: UICollectionViewFlowLayout())
        let searchNavigationController = UINavigationController(rootViewController: searchController)
        searchNavigationController.title = "Search"
        searchNavigationController.tabBarItem.image = UIImage(named: "search_icon")
        
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        let userProfileNavigationController = UINavigationController(rootViewController: userProfileController)
        userProfileNavigationController.title = "Profile"
        userProfileController.activeSegment = 1
        userProfileController.userUid = FIRAuth.auth()?.currentUser?.uid 
        userProfileNavigationController.tabBarItem.image = UIImage(named: "profile_icon")
        
        viewControllers = [homeNavigationController, searchNavigationController, userProfileNavigationController]
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        self.view.addGestureRecognizer(swipeLeft)

        //uncomment below to make custom tab bar with no gray bar on top
        tabBar.isTranslucent = false
        
        let topBorder = CALayer()
        topBorder.frame = CGRect(x: 0, y: 0, width: 1000, height: 0.5)
        topBorder.backgroundColor = UIColor(r: 229, g: 231, b: 235).cgColor
        
        tabBar.layer.addSublayer(topBorder)
        tabBar.clipsToBounds = true
    }
    
    @objc func swiped(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .left {
            if (self.tabBarController?.selectedIndex)! < 3 { // set your total tabs here
                self.tabBarController?.selectedIndex += 1
            }
        } else if gesture.direction == .right {
            if (self.tabBarController?.selectedIndex)! > 0 {
                self.tabBarController?.selectedIndex -= 1
            }
        }
    }
}
