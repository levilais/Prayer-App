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
    var dateJoined: Double?
    var firstName: String?
    var lastName: String?
    var userID: String?
    var userEmail: String?
    var profileImageAsString: String? // will be converted to url then image
    var profileImageAsData: Data?
    var profileImageAsImage: UIImage?
    
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
}




//class CircleUserObject: User {
//    var dateAddedToCircle: Double?
//    var lastAgreedInPrayerDate: Double?
//    var agreedInPrayerCount: Int?
//
//    func saveCircleUserToCurrentUser(ref: DatabaseReference, circleUser: User) {
//        if let userID = Auth.auth().currentUser?.uid {
//            if let circleUserID = circleUser.userID {
//                if let firstName = circleUser.firstName {
//                    ref.child("users").child(userID).child("circleUsers").child(circleUserID).child("firstName").setValue(firstName)
//                }
//                if let lastName = circleUser.lastName {
//                    ref.child("users").child(userID).child("circleUsers").child(circleUserID).child("lastName").setValue(lastName)
//                }
//                if let userEmail = circleUser.userEmail {
//                    ref.child("users").child(userID).child("circleUsers").child(circleUserID).child("userEmail").setValue(userEmail)
//                }
//                if let profileImageUrlString = circleUser.profileImageUrlString {
//                    ref.child("users").child(userID).child("circleUsers").child(circleUserID).child("profileImageUrlString").setValue(profileImageUrlString)
//                }
//                if let relationship = circleUser.relationship {
//                    ref.child("users").child(userID).child("circleUsers").child(circleUserID).child("relationship").setValue(relationship)
//                }
//                ref.child("users").child(userID).child("circleUsers").child(circleUserID).child("userID").setValue(circleUserID)
//                ref.child("users").child(userID).child("circleUsers").child(circleUserID).child("agreedInPrayerCount").setValue(0)
//                ref.child("users").child(userID).child("circleUsers").child(circleUserID).child("dateAddedToCircle").setValue(ServerValue.timestamp())
//            }
//        }
//    }
//}

