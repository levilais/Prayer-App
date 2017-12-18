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
    var profileImageUrlString: String? // will be converted to url then image
    var placeHolderImageData: Data?
    var relationship: String? // use enum.rawValue
    var hasBeenInvited: Bool?
    var nonMemberEmails: [CNLabeledValue<NSString>]?
    var nonMemberPhoneNumbers: [CNLabeledValue<CNPhoneNumber>]?
    
    enum relationshipToCurrentUser: String {
        case isCurrentUser = "isCurrentUser"
        case nonMember = "nonMember"
        case memberButNoRelation = "memberButNoRelation"
        case invited = "invited"
        case myCircleMember = "myCircleMember"
        case theirCircleMember = "theirCircleMember"
    }
    
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

class CircleUserObject: User {
    var dateAddedToCircle: Double?
    var lastAgreedInPrayerDate: Double?
    var agreedInPrayerCount: Int?
    
    func saveCircleUserToCurrentUser(ref: DatabaseReference, circleUser: User) {
        if let userID = Auth.auth().currentUser?.uid {
            if let circleUserID = circleUser.userID {
                if let firstName = circleUser.firstName {
                    ref.child("users").child(userID).child("circleUsers").child(circleUserID).child("firstName").setValue(firstName)
                }
                if let lastName = circleUser.lastName {
                    ref.child("users").child(userID).child("circleUsers").child(circleUserID).child("lastName").setValue(lastName)
                }
                if let userEmail = circleUser.userEmail {
                    ref.child("users").child(userID).child("circleUsers").child(circleUserID).child("userEmail").setValue(userEmail)
                }
                if let profileImageUrlString = circleUser.profileImageUrlString {
                    ref.child("users").child(userID).child("circleUsers").child(circleUserID).child("profileImageUrlString").setValue(profileImageUrlString)
                }
                if let relationship = circleUser.relationship {
                    ref.child("users").child(userID).child("circleUsers").child(circleUserID).child("relationship").setValue(relationship)
                }
                ref.child("users").child(userID).child("circleUsers").child(circleUserID).child("userID").setValue(circleUserID)
                ref.child("users").child(userID).child("circleUsers").child(circleUserID).child("agreedInPrayerCount").setValue(0)
                ref.child("users").child(userID).child("circleUsers").child(circleUserID).child("dateAddedToCircle").setValue(ServerValue.timestamp())
            }
        }
    }
}

// get emails from firebase and put into array
// for each email in cnContact emails check against firebase array
// if found, download user object for that email / if not assign nonMember User and use cnContactImage or profilePlaceholder
// get userID for that firebaseUser
// get userProfile for that firebaseUser
// check currentUser.circleMemmbers.userID
// if userID match drill down for relationship status / if not, assign memberButNoRelation
// get currentUser.circleMembers.userID.relationship status - assign relationship status
// append User to an array for SelectContacts view to unpack

