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

class CircleUser: User {

    var dateAddedToCircle: Date?
    var lastAgreedInPrayerDate: Date?
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

    func getFullName(user: CircleUser) -> String {
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
    
    func getRelationshipStatus(userToCheck: CircleUser) -> CircleUser {
        var user = userToCheck
        var userEmails = [CNLabeledValue<NSString>]()
        
        var relationshipDetermined = false
        user.relationshipToCurrentUser = CircleUser.userRelationshipToCurrentUser.nonMember.rawValue
        while relationshipDetermined == false {
            if let userEmailsCheck = user.circleMemberEmails {
                userEmails = userEmailsCheck
                for userEmail in userEmails {
                    let userEmailString = userEmail.value
                    for email in FirebaseHelper.firebaseUserEmails {
                        if userEmailString as String == email {
                            // user exists
                            userToCheck.userEmail = email
                            userToCheck.relationshipToCurrentUser = CircleUser.userRelationshipToCurrentUser.memberButNoRelation.rawValue
                            var i = 0
                            for circleMember in CurrentUser.firebaseCircleMembers {
                                if let circleMemberEmail = circleMember.userEmail {
                                    if userEmailString as String == circleMemberEmail {
                                        // invited
                                        print("NOTICE - Invitation determined and attempting to set user")
                                        user = CurrentUser.firebaseCircleMembers[i]
                                        relationshipDetermined = true
                                    }
                                }
                                i += 1
                            }
                        }
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
        user.dateAddedToCircle = Date()
        user.lastAgreedInPrayerDate = Date()
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

