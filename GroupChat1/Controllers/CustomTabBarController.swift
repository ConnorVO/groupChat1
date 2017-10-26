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
        
        let homeController = MessagesController(collectionViewLayout: UICollectionViewFlowLayout())
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
        
        //uncomment below to make custom tab bar with no gray bar on top
        /*tabBar.isTranslucent = false
        
        let topBorder = CALayer()
        topBorder.frame = CGRect(x: 0, y: 0, width: 1000, height: 0.5)
        topBorder.backgroundColor = UIColor(r: 229, g: 231, b: 235).cgColor
        
        tabBar.layer.addSublayer(topBorder)
        tabBar.clipsToBounds = true*/
    }
}
