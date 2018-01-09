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

class User {
    var key: String?
    var userRef: DatabaseReference?
    
    var dateJoinedPrayer: Double?
    var firstName: String?
    var lastName: String?
    var userID: String?
    var userEmail: String?
    var profileImageAsString: String? // will be converted to url then image
    var profileImageAsData: Data?
    var profileImageAsImage: UIImage?
    var usersCircleUserIds: [String]?
    var usersMembershipUserIds: [String]?
    
    func getFullName(user: User) -> String {
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
    
    func currentUserFromSnapshot(snapshot: DataSnapshot) -> User {
        let currentUser = User()
        
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
        }
        
        if let circleUsersDict = snapshot.childSnapshot(forPath: "circleUsers").value as? NSDictionary {
            currentUser.usersCircleUserIds = circleUsersDict.allKeys as? [String]
        }
        
        if let membershipUsersDict = snapshot.childSnapshot(forPath: "memberships").value as? NSDictionary {
            currentUser.usersMembershipUserIds = membershipUsersDict.allKeys as? [String]
        }
        
        return currentUser
    }
}

