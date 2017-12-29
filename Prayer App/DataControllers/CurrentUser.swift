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
//import CoreData

class CurrentUser {
    static var firebaseCircleMembers = [CircleUser]() {
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "circleMemberAdded"), object: nil, userInfo: nil)
        }
    }
    static var firebaseMembershipUsers = [MembershipUser]() {
        didSet {
            CurrentUser().updateMemberPrayers()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "membershipUserDidSet"), object: nil, userInfo: nil)
        }
    }
    static var membershipCirclePrayers = [CirclePrayer]() {
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "membershipPrayersUpdated"), object: nil, userInfo: nil)
        }
    }
    static var currentUserCirclePrayers = [CirclePrayer]() {
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "currentUserCirclePrayersUpdated"), object: nil, userInfo: nil)
            print("currentUserCirclePrayers changed")
        }
    }
    
    static var currentUser = User()
    
    func updateMemberPrayers() {
        for membershipUser in CurrentUser.firebaseMembershipUsers {
            if let relationship = membershipUser.membershipStatus {
                if relationship == MembershipUser.currentUserMembershipStatus.member.rawValue {
                    if let membershipUserID = membershipUser.userID {
                        Database.database().reference().child("users").child(membershipUserID).child("circlePrayers").observe(.childAdded) { (snapshot) in
                            if let userDictionary = snapshot.value as? NSDictionary {
                                var whoAgreedDict = NSDictionary()
                                if let whoAgreedDictCheck = snapshot.childSnapshot(forPath: "whoAgreed").value as? NSDictionary {
                                    whoAgreedDict = whoAgreedDictCheck
                                }
                                
                                let circlePrayer = FirebaseHelper().circlePrayerFromUserDictionary(userDictionary: userDictionary, whoAgreedDict: whoAgreedDict)
                                
                                if CurrentUser.membershipCirclePrayers.count > 0 {
                                    var matchDetermined = false
                                    var matchExists = false
                                    var i = 0
                                    while matchDetermined == false {
                                        for membershipCirclePrayer in CurrentUser.membershipCirclePrayers {
                                            if let membershipCirclePrayerID = membershipCirclePrayer.prayerID {
                                                if let circlePrayerID = circlePrayer.prayerID {
                                                    if membershipCirclePrayerID == circlePrayerID {
                                                        CurrentUser.membershipCirclePrayers[i] = circlePrayer
                                                        matchExists = true
                                                        matchDetermined = true
                                                    }
                                                }
                                            }
                                            i += 1
                                        }
                                        matchDetermined = true
                                    }
                                    if matchExists == false {
                                        CurrentUser.membershipCirclePrayers.append(circlePrayer)
                                    }
                                } else {
                                    CurrentUser.membershipCirclePrayers.append(circlePrayer)
                                }
                            }
                            // reload data here if necessary
                        }
                    }
                }
            }
        }
    }
    
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
