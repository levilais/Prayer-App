//
//  MembershipUser.swift
//  Prayer App
//
//  Created by Levi on 12/19/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class MembershipUser: CircleUser {
    var membershipUserCircleRef: DatabaseReference?
    var currentUserMembershipRef: DatabaseReference?
    
    var membershipStatus: String?
    var membershipUserCircleIds: [String]?
    var membershipUserCircleUsers: [CircleUser]?
    var membershipCirclePrayers: [CirclePrayer]?
    
    enum currentUserMembershipStatus: String {
        case invited = "invited"
        case member = "member"
        case declined = "declined"
    }
    
    func membershipUserFromSnapshot(snapshot: DataSnapshot) -> MembershipUser {
        let membershipUser = MembershipUser()
        
        membershipUser.key = snapshot.key
        membershipUser.userRef = snapshot.ref
        
        if let userDictionary = snapshot.value as? NSDictionary {
            if let membershipStatus = userDictionary["membershipStatus"] as? String {
                membershipUser.membershipStatus = membershipStatus
            }
            if let firstName = userDictionary["firstName"] as? String {
                membershipUser.firstName = firstName
            }
            if let lastName = userDictionary["lastName"] as? String {
                membershipUser.lastName = lastName
            }
            if let userID = userDictionary["userID"] as? String {
                membershipUser.userID = userID
            }
            if let userEmail = userDictionary["userEmail"] as? String {
                membershipUser.userEmail = userEmail
            }
            if let profileImageUrlString = userDictionary["profileImageURL"] as? String {
                membershipUser.profileImageAsString = profileImageUrlString
            }
            if let dateInvitedDouble = userDictionary["dateInvited"] as? Double {
                membershipUser.dateInvited = dateInvitedDouble
            }
        }
        
        if let circleUsersDict = snapshot.childSnapshot(forPath: "circleUsers").value as? NSDictionary {
            membershipUser.membershipUserCircleIds = circleUsersDict.allKeys as? [String]
        }
        
        if let membershipKey = membershipUser.key {
            if let currentUserKey = CurrentUser.currentUser.key {
                membershipUser.currentUserMembershipRef = Database.database().reference().child("users").child(membershipKey).child("circleUsers").child(currentUserKey)
                membershipUser.membershipUserCircleRef = Database.database().reference().child("users").child(currentUserKey).child("memberships").child(membershipKey)
            }
        }
        print("before")
        getMembershipUserProfileImage(membershipUser: membershipUser)
        print("after")
        
        return membershipUser
    }
    
    func getMembershipUserProfileImage(membershipUser: MembershipUser) {
        if let urlString = membershipUser.profileImageAsString {
            if let url = URL(string: urlString) {
                URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                    if error != nil {
                        print(error!.localizedDescription)
                        return
                    }
                    if let imageData = data {
                        if let image = UIImage(data: imageData) {
                            membershipUser.profileImageAsImage = image
                            var i = 0
                            for user in CurrentUser.firebaseMembershipUsers {
                                if let email = user.userEmail {
                                    if let userEmail = membershipUser.userEmail {
                                        if email == userEmail {
                                            CurrentUser.firebaseMembershipUsers[i] = membershipUser
                                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "membershipUserDidSet"), object: nil, userInfo: nil)
                                        }
                                    }
                                }
                                i += 1
                            }
                        }
                    }
                }).resume()
            }
        }
    }
    
    func getMembershipUserCircleUsers(membershipUser: MembershipUser) {
        if let urlString = membershipUser.profileImageAsString {
            if let url = URL(string: urlString) {
                URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                    if error != nil {
                        print(error!.localizedDescription)
                        return
                    }
                    if let imageData = data {
                        if let image = UIImage(data: imageData) {
                            membershipUser.profileImageAsImage = image
                            var userExists = false
                            var i = 0
                            var userExistsDetermined = false
                            while userExistsDetermined == false {
                                for user in CurrentUser.firebaseMembershipUsers {
                                    if let email = user.userEmail {
                                        if let userEmail = membershipUser.userEmail {
                                            if email == userEmail {
                                                userExists = true
                                                userExistsDetermined = true
                                            }
                                        }
                                    }
                                    i += 1
                                }
                                userExistsDetermined = true
                            }
                            if userExists == false {
                                CurrentUser.firebaseMembershipUsers.append(membershipUser)
                                
                                if let membershipUserID = membershipUser.userID {
                                    Database.database().reference().child("users").child(membershipUserID).child("circleUsers").observe(.childAdded, with: { (snapshot) in
                                        if let userDictionary = snapshot.value as? NSDictionary {
                                            if let profileImageString = userDictionary["profileImageURL"] as? String {
                                                if let url = URL(string: profileImageString) {
                                                    URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                                                        if error != nil {
                                                            print(error!.localizedDescription)
                                                            return
                                                        }
                                                        if let imageData = data {
                                                            if let image = UIImage(data: imageData) {
                                                                var i = 0
                                                                for user in CurrentUser.firebaseMembershipUsers {
                                                                    if let userID = user.userID {
                                                                        if let membershipUserID = membershipUser.userID {
                                                                            if userID == membershipUserID {
                                                                                let newUser = CircleUser()
                                                                                var newUsersArray = [CircleUser]()
                                                                                var circleUserID = String()
                                                                                var circleUserAgreedCount = Int()
                                                                                if let circleUserIDCheck = userDictionary["userID"] as? String {
                                                                                    circleUserID = circleUserIDCheck
                                                                                }
                                                                                
                                                                                if let circleUserAgreedCheck = userDictionary["agreedInPrayerCount"] as? Int {
                                                                                    circleUserAgreedCount = circleUserAgreedCheck
                                                                                }
                                                                                
                                                                                if let existingUserArray = user.membershipUserCircleUsers {
                                                                                    newUsersArray = existingUserArray
                                                                                    newUser.profileImageAsImage = image
                                                                                    newUser.userID = circleUserID
                                                                                    newUser.agreedInPrayerCount = circleUserAgreedCount
                                                                                    newUsersArray.append(newUser)
                                                                                    user.membershipUserCircleUsers = newUsersArray
                                                                                    CurrentUser.firebaseMembershipUsers[i] = user
                                                                                } else {
                                                                                    newUser.profileImageAsImage = image
                                                                                    newUser.userID = circleUserID
                                                                                    newUser.agreedInPrayerCount = circleUserAgreedCount
                                                                                    newUsersArray.append(newUser)
                                                                                    user.membershipUserCircleUsers = newUsersArray
                                                                                    CurrentUser.firebaseMembershipUsers[i] = user
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                    i += 1
                                                                }
                                                            }
                                                        }
                                                    }).resume()
                                                }
                                            }
                                            
                                        }
                                    })
                                }
                            }
                        }
                    }
                }).resume()
            }
        }
    }
    
    func declineInvite(membershipUser: MembershipUser) {
        if let membershipRef = membershipUser.currentUserMembershipRef {
            if let circleRef = membershipUser.membershipUserCircleRef {
                membershipRef.removeValue()
                circleRef.removeValue()
            }
        }
        
        var i = 0
        for firebaseMembershipUser in CurrentUser.firebaseMembershipUsers {
            if let membershipUserEmail = membershipUser.userEmail {
                if let emailToCheck = firebaseMembershipUser.userEmail {
                    if membershipUserEmail == emailToCheck {
                        CurrentUser.firebaseMembershipUsers.remove(at: i)
                    }
                }
            }
            i += 1
        }
    }
}

