//
//  CurrentUser.swift
//  Prayer App
//
//  Created by Levi on 11/25/17.
//  Copyright © 2017 App Volks. All rights reserved.
//


import Foundation
import Firebase
import FirebaseStorage
import UIKit
import CoreData

class CurrentUser {
    static var firebaseCircleMembers = [CircleUser]() {
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "circleMemberAdded"), object: nil, userInfo: nil)
        }
    }
    
    static var currentUser = User()
    
//    static var isLoggedIn: Bool?
//    static var hasAllowedContactAccess = false
    
    func setupCurrentUserFirstNameWelcomeLabel(label: UILabel) -> UILabel {
        if Auth.auth().currentUser != nil {
            if let userID = Auth.auth().currentUser?.uid {
                Database.database().reference().child("users").child(userID).observe(.value) { (snapshot) in
                    if let userDictionary = snapshot.value as? NSDictionary {
                        if let firstName = userDictionary["firstName"] as? String {
                            label.text =  "Good afternoon, \(firstName)"
                        }
                    }
                }
            }
        }
        return label
    }
    
    func setProfileImageButton(button: UIButton) -> UIButton {
        if Auth.auth().currentUser != nil {
            if let userID = Auth.auth().currentUser?.uid {
                Database.database().reference().child("users").child(userID).observe(.value) { (snapshot) in
                    if let userDictionary = snapshot.value as? NSDictionary {
                        if let imageURLString = userDictionary["profileImageURL"] as? String {
                            if let url = URL(string: imageURLString) {
                                button.sd_setBackgroundImage(with: url, for: .normal, completed: { (image, error, cacheType, imageURL) in
                                })
                            }
                        }
                    }
                }
            }
        }
        return button
    }
    
    // HELPER METHOD FOR SETTING INITIAL PROFILE IMAGE
    func profileImageFromNameAsData(firstName: String) -> Data {
        var imageDataToSave = Data()
        let firstLetter = String(describing: firstName.first!)
        let uppercasedFirstLetter = firstLetter.uppercased()
        let imageNameString = "profilePlaceHolderImage" + uppercasedFirstLetter + ".pdf"
        if let image = UIImage(named: imageNameString) {
            if let imageData = UIImagePNGRepresentation(image) {
                imageDataToSave = imageData
            }
        }
        return imageDataToSave
    }
}
