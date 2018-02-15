//
//  CircleUsers.swift
//  Prayer App
//
//  Created by Levi on 11/25/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation
import UIKit
import Contacts
import ContactsUI
import Firebase

class CircleUser: CustomUser {
    var currentUserCircleRef: DatabaseReference?
    var circleUserMembershipRef: DatabaseReference?
    
    var dateJoinedCircle: Double?
    var dateInvited: Double?
    var lastAgreedInPrayerDate: Double?
    var agreedInPrayerCount: Int?
    var relationshipToCurrentUser: String?
    var circleMemberEmails: [CNLabeledValue<NSString>]?
    var circleMemberPhoneNumbers: [CNLabeledValue<CNPhoneNumber>]?
    var hasBeenInvited: Bool?
    
    enum userRelationshipToCurrentUser: String {
        case nonMember = "nonMember"
        case memberButNoRelation = "memberButNoRelation"
        case invited = "invited"
        case myCircleMember = "myCircleMember"
    }
    
    func circleUserFromSnapshot(snapshot: DataSnapshot) -> CircleUser {
        let circleUser = CircleUser()
        
        circleUser.key = snapshot.key
        circleUser.userRef = snapshot.ref
        
        if let userDictionary = snapshot.value as? NSDictionary {
            if let uid = userDictionary["userID"] as? String {
                circleUser.userID = uid
            }
            if let profileImageUrlString = userDictionary["profileImageURL"] as? String {
                circleUser.profileImageAsString = profileImageUrlString
            }
            
            if let firstName = userDictionary["firstName"] as? String {
                circleUser.firstName = firstName
            }
            
            if let lastName = userDictionary["lastName"] as? String {
                circleUser.lastName = lastName
            }
            
            if let userEmail = userDictionary["userEmail"] as? String {
                circleUser.userEmail = userEmail
            }
            
            if let relationship = userDictionary["relationship"] as? String {
                circleUser.relationshipToCurrentUser = relationship
            }
            if let dateJoinedCircleCheck = userDictionary["dateJoinedCircle"] as? Double {
                circleUser.dateJoinedCircle = dateJoinedCircleCheck
            }
            if let agreedCountCheck = userDictionary["agreedInPrayerCount"] as? Int {
                circleUser.agreedInPrayerCount = agreedCountCheck
            }
            if let lastAgreedDateCheck = userDictionary["lastAgreedInPrayerDate"] as? Double {
                circleUser.lastAgreedInPrayerDate = lastAgreedDateCheck
            }
            if let userPhone = userDictionary["userPhone"] as? String {
                circleUser.userPhone = userPhone
            }
        }
        
        if let circleKey = circleUser.key {
            if let currentUserKey = CurrentUser.currentUser.key {
                circleUser.circleUserMembershipRef = Database.database().reference().child("users").child(circleKey).child("memberships").child(currentUserKey)
                circleUser.currentUserCircleRef = Database.database().reference().child("users").child(currentUserKey).child("circleUsers").child(circleKey)
                circleUser.messagingTokensRef = Database.database().reference().child("users").child(circleKey).child("messagingTokens")
            }
        }
        
        setMessagingTokens(circleUser: circleUser)
        
        setCircleUserProfileImageFromFirebase(circleUser: circleUser)
        
        return circleUser
    }
    
    func setCircleUserProfileImageFromFirebase(circleUser: CircleUser) {
        if let urlString = circleUser.profileImageAsString {
            if let url = URL(string: urlString) {
                URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                    if error != nil {
                        print(error!.localizedDescription)
                        return
                    }
                    if let imageData = data {
                        if let image = UIImage(data: imageData) {
                            circleUser.profileImageAsImage = image
                            var i = 0
                            for user in CurrentUser.firebaseCircleMembers {
                                if let email = user.userEmail {
                                    if let userEmail = circleUser.userEmail {
                                        if email == userEmail {
                                            CurrentUser.firebaseCircleMembers[i] = circleUser
                                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "circleUserProfileImageDidSet"), object: nil, userInfo: nil)
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
    
    func setMessagingTokens(circleUser: CircleUser) {
        if let messagingTokensRef = circleUser.messagingTokensRef {
            messagingTokensRef.observeSingleEvent(of: .value) { (snapshot) in
                if let tokensDict = snapshot.value as? NSDictionary {
                    if let tokens = Array(tokensDict.allKeys) as? [String] {
                        circleUser.messagingTokens = tokens
                        var i = 0
                        for user in CurrentUser.firebaseCircleMembers {
                            if let email = user.userEmail {
                                if let userEmail = circleUser.userEmail {
                                    if email == userEmail {
                                        CurrentUser.firebaseCircleMembers[i] = circleUser
                                    }
                                }
                            }
                            i += 1
                        }
                    }
                }
            }
        }
    }
    
    func removeUserFromCircle(circleUser: CircleUser) {
        if let circleRef = circleUser.currentUserCircleRef {
            if let memberRef = circleUser.circleUserMembershipRef {
                circleRef.removeValue()
                memberRef.removeValue()
                
                var i = 0
                for firebaseCircleUser in CurrentUser.firebaseCircleMembers {
                    if let circleUserEmail = circleUser.userEmail {
                        if let emailToCheck = firebaseCircleUser.userEmail {
                            if circleUserEmail == emailToCheck {
                                CurrentUser.firebaseCircleMembers.remove(at: i)
                                if CurrentUser.firebaseCircleMembers.count == 0 {
                                    if let userRef = CurrentUser.currentUser.userRef {
                                        userRef.child("circlePrayers").removeValue()
                                    }
                                }
                            }
                        }
                    }
                    i += 1
                }
            }
        }
    }
    
    func getRelationshipStatus(userToCheck: CircleUser) -> CircleUser {
        var user = userToCheck
        var userEmails = [CNLabeledValue<NSString>]()
        var userPhoneNumbers = [CNLabeledValue<CNPhoneNumber>]()
        
        var relationshipDetermined = false
        user.relationshipToCurrentUser = CircleUser.userRelationshipToCurrentUser.nonMember.rawValue
        while relationshipDetermined == false {
            if let userEmailsCheck = user.circleMemberEmails {
                userEmails = userEmailsCheck
            }
            if let userPhoneNumbersCheck = user.circleMemberPhoneNumbers {
                userPhoneNumbers = userPhoneNumbersCheck
            }
            
            var memberExists = false
            for userEmail in userEmails {
                let userEmailString = userEmail.value
                let cleanEmail = userEmailString.lowercased
                for fbUser in FirebaseHelper.firebaseUsers {
                    if let email = fbUser.userEmail {
                        if cleanEmail == email {
                            // user exists
                            memberExists = true
                            if let userID = fbUser.userID {
                                user.userID = userID
                            }
                        }
                    }
                }
            }
            for userPhoneNumber in userPhoneNumbers {
                let cleanPhoneNumber = (userPhoneNumber.value).value(forKey: "digits") as! String
                for fbUser in FirebaseHelper.firebaseUsers {
                    if let phoneNumber = fbUser.userPhone?.replacingOccurrences(of: "-", with: "") {
                        if cleanPhoneNumber == phoneNumber {
                            // user exists
                            memberExists = true
                            if let userID = fbUser.userID {
                                user.userID = userID
                            }
                        }
                    }
                }
            }
            
            if memberExists == true {
                user.relationshipToCurrentUser = CircleUser.userRelationshipToCurrentUser.memberButNoRelation.rawValue
                if let userID = user.userID {
                    var i = 0
                    for circleMember in CurrentUser.firebaseCircleMembers {
                        if let circleMemberID = circleMember.userID {
                            if userID == circleMemberID {
                                user = CurrentUser.firebaseCircleMembers[i]
                                relationshipDetermined = true
                            }
                        }
                        i += 1
                    }
                }
            }
            relationshipDetermined = true
        }
        return user
    }
}

extension CircleUser {
    func setFromCnContact(cnContact: CNContact) -> CircleUser {        
        let user = CircleUser()
        user.firstName = cnContact.givenName
        user.lastName = cnContact.familyName
        user.hasBeenInvited = false
        user.agreedInPrayerCount = 0
        
        var imageDataToSave = Data()
        if let profileImageCheck = cnContact.imageData {
            imageDataToSave = profileImageCheck
        } else {
            var fullName = ""
            if let first = user.firstName {
                if let last = user.lastName {
                    fullName = first + last
                    if fullName == "" {
                        if let image = UIImage(named: "profilImageDefault.pdf") {
                            imageDataToSave = UIImagePNGRepresentation(image)!
                        }
                    } else {
                        if let firstLetter = fullName.first {
                            let firstLetterString = String(describing: firstLetter)
                            let uppercasedFirstLetter = firstLetterString.uppercased()
                            let imageNameString = "profilePlaceHolderImage" + uppercasedFirstLetter + ".pdf"
                            if let image = UIImage(named: imageNameString) {
                                imageDataToSave = UIImagePNGRepresentation(image)!
                            }
                        }
                    }
                }
            }
        }

        user.profileImageAsData = imageDataToSave
        user.circleMemberEmails = cnContact.emailAddresses
        user.circleMemberPhoneNumbers = cnContact.phoneNumbers
        
        return user
    }
}

