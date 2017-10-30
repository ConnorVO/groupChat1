//
//  Extensions.swift
//  Group Chat App Try 1
//
//  Created by Connor Van Ooyen on 9/25/17.
//  Copyright © 2017 Connor Van Ooyen. All rights reserved.
//

import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(urlString: String) {
        
        self.image = nil // prevents flashing of image when scrolling
        
        //check cache for image first
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject) as? UIImage {
            self.image = cachedImage
            return
        }
        
        //if no cached image, then downloads
        let url = URL(string: urlString)
        
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            
            if error != nil {
                print("Loading profile image error: ", error as Any)
                return
            }
            
            DispatchQueue.main.async {
                
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                    
                    self.image = downloadedImage
                }
                self.image = UIImage(data: data!)
            }
            
        }).resume()
    }
}


extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
    
    struct blue {
        static let main = UIColor(r: 61, g: 91, b: 151)
        static let button = UIColor(r: 80, g: 101, b: 161)
    }
    
    struct orange {
        static let original = UIColor(r: 255, g: 127.5, b:0)
        static let main = UIColor(r: 248, g: 180, b: 58)
    }
    
    struct green {
        static let original = UIColor(r: 0, g: 0, b: 1)
        static let main = UIColor(r: 34, g: 200, b: 112)
        static let button = UIColor(r: 44, g: 224, b: 128)
        static let darker = UIColor(r: 28, g: 178 , b: 99)
    }
}

