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

class CircleUser {
    var firstName: String?
    var lastName: String?
    var dateAdded: Date?
    var lastAgreedInPrayerDate: Date?
    var agreedInPrayerCount: Int?
    var profileImage: Data?
    var circleUserID: String?
    var circleMemberEmails: [CNLabeledValue<NSString>]?
    var circleMemberPhoneNumbers: [CNLabeledValue<CNPhoneNumber>]?
    var userRelationshipToCurrentUser: userRelationshipToCurrentUser?
    var hasBeenInvited: Bool?
    
    enum userRelationshipToCurrentUser: Int {
        case nonMember = 0
        case memberButNoRelation = 1
        case invited = 2
        case myCircleMember = 3
        case theirCircleMember = 4
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
    
    func printCircleUser(user: CircleUser) {
        if let firstNameCheck = user.firstName {
            print("firstName: \(firstNameCheck)")
        }
        if let lastNameCheck = user.lastName {
            print("lastName: \(lastNameCheck)")
        }
        if let hasBeenInvitedCheck = user.hasBeenInvited {
            print("hasBeenInvited: \(hasBeenInvitedCheck)")
        }
        if let dateAddedCheck = user.dateAdded {
            print("dateAdded: \(dateAddedCheck)")
        }
        if let lastAgreeCheck = user.lastAgreedInPrayerDate {
            print("lastAgreedInPrayerDate: \(lastAgreeCheck)")
        }
        if let agreedCountCheck = user.agreedInPrayerCount {
            print("agreedInPrayerCount: \(agreedCountCheck)")
        }
        
        if let profilImageCheck = user.profileImage {
                print("profileImage: \(profilImageCheck)")
        } else {
            print("profileImage: no image")
        }
        
        if let circleUserIdCheck = user.circleUserID {
            print("circleUserID: \(circleUserIdCheck)")
        }
        if let circleMemberEmailsCheck = user.circleMemberEmails {
            print("circleMemberEmails: \(circleMemberEmailsCheck)")
        }
        if let emailsCount = user.circleMemberEmails?.count {
            print("circleMemberEmails.count: \(emailsCount)")
        }
        if let phoneNumbers = user.circleMemberPhoneNumbers {
            print("circleMemberPhoneNumbers: \(phoneNumbers)")
        }
        if let phoneNumbersCount = user.circleMemberPhoneNumbers?.count {
            print("circleMemberPhoneNumbers.count: \(phoneNumbersCount))")
        }
        if let userRelationshipCheck = user.userRelationshipToCurrentUser {
            print("userRelationshipToCurrentUser: \(userRelationshipCheck))")
        }
    }
    
    func getRelationshipStatus(userToCheck: CircleUser) -> CircleUser {
        var user = userToCheck
        var circleMemberEmails = [CNLabeledValue<NSString>]()
        var userEmails = [CNLabeledValue<NSString>]()
        var circleMemberPhonenumbers = [CNLabeledValue<CNPhoneNumber>]()
        var userPhoneNumbers = [CNLabeledValue<CNPhoneNumber>]()
        
        var matchFound = false
        user.userRelationshipToCurrentUser = CircleUser.userRelationshipToCurrentUser.nonMember
        while matchFound == false {
            //                        print("started while loop")
            for circleMember in CurrentUser.circleMembers {
                if let circleMemberEmailCheck = circleMember.circleMemberEmails {
                    circleMemberEmails = circleMemberEmailCheck
                }
                for circleMemberEmail in circleMemberEmails {
                    print("circleMemberEmail: \(circleMemberEmail)")
                    if let userEmailsCheck = user.circleMemberEmails {
                        userEmails = userEmailsCheck
                    }
                    for userEmail in userEmails {
                        print("userEmail: \(userEmail)")
                        if circleMemberEmail == userEmail {
                            print("match found")
                            user = circleMember
                            user.userRelationshipToCurrentUser = CircleUser.userRelationshipToCurrentUser.invited
                            matchFound = true
                        }
                    }
                }
                
                if let circleMemberPhoneNumbersCheck = circleMember.circleMemberPhoneNumbers {
                    circleMemberPhonenumbers = circleMemberPhoneNumbersCheck
                }
                if let userPhoneNumbersCheck = user.circleMemberPhoneNumbers {
                    userPhoneNumbers = userPhoneNumbersCheck
                }
                for circleMemberPhoneNumber in circleMemberPhonenumbers {
                    for userPhoneNumber in userPhoneNumbers {
                        if circleMemberPhoneNumber == userPhoneNumber {
                            user = circleMember
                            user.userRelationshipToCurrentUser = CircleUser.userRelationshipToCurrentUser.invited
                            print("match found")
                            matchFound = true
                        }
                    }
                }
            }
            matchFound = true
        }
        if let relationship = user.userRelationshipToCurrentUser {
             print("userRelationship: \(relationship)")
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
        user.dateAdded = Date()
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
        
        user.profileImage = imageDataToSave
        
        user.circleUserID = "userID.\(String(describing: user.dateAdded)).\(String(describing: user.firstName)).\(String(describing: user.lastName))"
        user.circleMemberEmails = cnContact.emailAddresses
        user.circleMemberPhoneNumbers = cnContact.phoneNumbers
        
        return user
    }
}

