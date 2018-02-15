//
//  User.swift
//  Prayer App
//
//  Created by Levi on 12/17/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation

import Foundation
import Firebase
import Contacts
import ContactsUI

class CustomUser {
    var key: String?
    var userRef: DatabaseReference?
    var messagingTokensRef: DatabaseReference?
    
    var dateJoinedPrayer: Double?
    var firstName: String?
    var lastName: String?
    var userID: String?
    var userEmail: String?
    var userPhone: String?
    var profileImageAsString: String?
    var profileImageAsData: Data?
    var profileImageAsImage: UIImage?
    var usersCircleUserIds: [String]?
    var usersMembershipUserIds: [String]?
    var messagingTokens: [String]?
    
    func getFullName(user: CustomUser) -> String {
        var fullName = ""
        if let first = user.firstName {
            if let last = user.lastName {
                fullName += first
                if fullName != "" {
                    fullName += " " + last
                } else {
                    fullName += last
                }
            }
        }
        return fullName
    }
    
    func currentUserFromSnapshot(snapshot: DataSnapshot) -> CustomUser {
        let currentUser = CustomUser()
        
        currentUser.key = snapshot.key
        currentUser.userRef = snapshot.ref
        
        if let userDictionary = snapshot.value as? NSDictionary {
            if let firstName = userDictionary["firstName"] as? String {
                currentUser.firstName = firstName
            }
            if let lastName = userDictionary["lastName"] as? String {
                currentUser.lastName = lastName
            }
            if let userEmail = userDictionary["userEmail"] as? String {
                currentUser.userEmail = userEmail
            }
            if let profileImageAsUrlString = userDictionary["profileImageURL"] as? String {
                currentUser.profileImageAsString = profileImageAsUrlString
            }
            if let userID = userDictionary["userID"] as? String {
                currentUser.userID = userID
            }
            if let userPhone = userDictionary["userPhone"] as? String {
                currentUser.userPhone = userPhone
            }
        }
        
        if let circleUsersDict = snapshot.childSnapshot(forPath: "circleUsers").value as? NSDictionary {
            currentUser.usersCircleUserIds = circleUsersDict.allKeys as? [String]
        }
        
        if let membershipUsersDict = snapshot.childSnapshot(forPath: "memberships").value as? NSDictionary {
            currentUser.usersMembershipUserIds = membershipUsersDict.allKeys as? [String]
        }
        
        return currentUser
    }
    
    func firebaseUserFromDictionary(userDictionary: NSDictionary) -> CustomUser {
        let user = CustomUser()
        
        if let firstName = userDictionary["firstName"] as? String {
            user.firstName = firstName
        }
        if let lastName = userDictionary["lastName"] as? String {
            user.lastName = lastName
        }
        if let userEmail = userDictionary["userEmail"] as? String {
            user.userEmail = userEmail
        }
        if let userID = userDictionary["userID"] as? String {
            user.userID = userID
        }
        if let userPhone = userDictionary["userPhone"] as? String {
            user.userPhone = userPhone
        }
        
        return user
    }
}

