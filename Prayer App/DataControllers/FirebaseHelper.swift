//
//  FirebaseHelper.swift
//  Prayer App
//
//  Created by Levi on 12/1/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseDatabase
import CoreData

class FirebaseHelper {
    static var firebaseUserEmails = [String]()
    
    func getUsers() {
        Database.database().reference().child("users").observe(.childAdded) { (snapshot) in
            if let userDictionary = snapshot.value as? NSDictionary {
                if let email = userDictionary["userEmail"] as? String {
                    if !FirebaseHelper.firebaseUserEmails.contains(email) {
                        FirebaseHelper.firebaseUserEmails.append(email)
                    }
                }
            }
        }
    }
    
    func getUserEmails(completion: @escaping (Bool) -> Void) {
        Database.database().reference().child("users").queryOrderedByKey().observeSingleEvent(of: .value) { (snapshot) in
            if let userDictionary = snapshot.value as? NSDictionary {
                if let email = userDictionary["userEmail"] as? String {
                    if !FirebaseHelper.firebaseUserEmails.contains(email) {
                        FirebaseHelper.firebaseUserEmails.append(email)
                    }
                }
            }
            completion(true)
        }
    }
    
    func loadFirebaseData() {
        if let userID = Auth.auth().currentUser?.uid {
            Database.database().reference().child("users").child(userID).child("circleUsers").observe(.childAdded, with: { snapshot in
                if snapshot.value != nil {
                    if let userDictionary = snapshot.value as? NSDictionary {
                        if let uid = userDictionary["userUID"] as? String {
                            if let profileImageUrlString = userDictionary["profileImageURL"] as? String {
                                if let firstName = userDictionary["firstName"] as? String {
                                    if let lastName = userDictionary["lastName"] as? String {
                                        if let userEmail = userDictionary["userEmail"] as? String {
                                            if let relationship = userDictionary["relationship"] as? String {
                                                    let circleUser = CircleUser()
                                                    circleUser.firstName = firstName
                                                    circleUser.lastName = lastName
                                                    circleUser.userID = uid
                                                    circleUser.userEmail = userEmail
                                                    circleUser.profileImageAsString = profileImageUrlString
                                                    circleUser.relationshipToCurrentUser = relationship
                                                if let dateJoinedCircleCheck = userDictionary["dateJoinedCircle"] as? Double {
                                                    circleUser.dateJoinedCircle = dateJoinedCircleCheck
                                                }
                                                if let agreedCountCheck = userDictionary["agreedInPrayerCount"] as? Int {
                                                    circleUser.agreedInPrayerCount = agreedCountCheck
                                                }
                                                if let lastAgreedDateCheck = userDictionary["lastAgreedInPrayerDate"] as? Double {
                                                    circleUser.lastAgreedInPrayerDate = lastAgreedDateCheck
                                                }
                                                    
                                                    var userExists = false
                                                    if CurrentUser.firebaseCircleMembers.count > 0 {
                                                        var matchDetermined = false
                                                        while matchDetermined == false {
                                                            for userToCheck in CurrentUser.firebaseCircleMembers {
                                                                if let userToCheckEmail = userToCheck.userEmail {
                                                                    if userToCheckEmail == userEmail {
                                                                        userExists = true
                                                                        matchDetermined = true
                                                                    }
                                                                }
                                                            }
                                                            matchDetermined = true
                                                        }
                                                    }
                                                    if userExists != true {
                                                        CurrentUser.firebaseCircleMembers.append(circleUser)
                                                    }
                                                    self.setCircleUserProfileImageFromFirebase(circleUser: circleUser)
                                                }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    print ("no circle users found")
                }
            })
            
            Database.database().reference().child("users").child(userID).observe(.value) { (snapshot) in
                if let userDictionary = snapshot.value as? NSDictionary {
                    let user = User()

                    if let firstName = userDictionary["firstName"] as? String {
                        user.firstName = firstName
                    }
                    if let lastName = userDictionary["lastName"] as? String {
                        user.lastName = lastName
                    }
                    if let userEmail = userDictionary["userEmail"] as? String {
                        user.userEmail = userEmail
                    }
                    if let profileImageAsUrlString = userDictionary["profileImageURL"] as? String {
                        user.profileImageAsString = profileImageAsUrlString
                    }
                    user.userID = userID
                    CurrentUser.currentUser = user
                }
            }
        }
    }
    
    func inviteUserToCircle(userEmail: String, ref: DatabaseReference) {
        if let userID = Auth.auth().currentUser?.uid {
            ref.child("users").queryOrdered(byChild: "userEmail").queryEqual(toValue: userEmail).observeSingleEvent(of: .childAdded, with: { snapshot in
                if snapshot.value != nil {
                    if let userDictionary = snapshot.value as? NSDictionary {
                        if let uid = userDictionary["userID"] as? String {
                            if let profileImageUrlString = userDictionary["profileImageURL"] as? String {
                                if let firstName = userDictionary["firstName"] as? String {
                                    if let lastName = userDictionary["lastName"] as? String {
                                        ref.child("users").child(userID).child("circleUsers").child(uid).child("firstName").setValue(firstName)
                                        ref.child("users").child(userID).child("circleUsers").child(uid).child("lastName").setValue(lastName)
                                        ref.child("users").child(userID).child("circleUsers").child(uid).child("userEmail").setValue(userEmail)
                                        ref.child("users").child(userID).child("circleUsers").child(uid).child("userUID").setValue(uid)
                                        ref.child("users").child(userID).child("circleUsers").child(uid).child("profileImageURL").setValue(profileImageUrlString)
                                    ref.child("users").child(userID).child("circleUsers").child(uid).child("relationship").setValue(CircleUser.userRelationshipToCurrentUser.invited.rawValue)
                                        ref.child("users").child(userID).child("circleUsers").child(uid).child("dateInvited").setValue(ServerValue.timestamp())
                                        
                                        let circleUser = CircleUser()
                                        circleUser.firstName = firstName
                                        circleUser.lastName = lastName
                                        circleUser.userID = uid
                                        circleUser.userEmail = userEmail
                                        circleUser.profileImageAsString = profileImageUrlString
                                        circleUser.relationshipToCurrentUser = CircleUser.userRelationshipToCurrentUser.invited.rawValue
                                        
                                        CurrentUser.firebaseCircleMembers.append(circleUser)
                                        self.setCircleUserProfileImageFromFirebase(circleUser: circleUser)
                                        
                                        self.sendInviteToUser(userEmail: userEmail, ref: ref)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    print ("user not found")
                }
            })
        }
    }
    
    func sendInviteToUser(userEmail: String, ref: DatabaseReference) {
        if let userID = Auth.auth().currentUser?.uid {
            ref.child("users").queryOrdered(byChild: "userEmail").queryEqual(toValue: userEmail).observeSingleEvent(of: .childAdded, with: { snapshot in
                if snapshot.value != nil {
                    if let userDictionary = snapshot.value as? NSDictionary {
                        if let uid = userDictionary["userID"] as? String {
                            if let currentUserFirstName = CurrentUser.currentUser.firstName {
                                if let currentUserLastName = CurrentUser.currentUser.lastName {
                                    if let currentUserProfileImageUrl = CurrentUser.currentUser.profileImageAsString {
                                        if let currentUserEmail = CurrentUser.currentUser.userEmail {
                                            ref.child("users").child(uid).child("memberships").child(userID).child("firstName").setValue(currentUserFirstName)
                                            ref.child("users").child(uid).child("memberships").child(userID).child("lastName").setValue(currentUserLastName)
                                            ref.child("users").child(uid).child("memberships").child(userID).child("userID").setValue(userID)
                                            ref.child("users").child(uid).child("memberships").child(userID).child("profileImageURL").setValue(currentUserProfileImageUrl)
                                            ref.child("users").child(uid).child("memberships").child(userID).child("userEmail").setValue(currentUserEmail)
                                            ref.child("users").child(uid).child("memberships").child(userID).child("membershipStatus").setValue(MembershipUser.currentUserMembershipStatus.invited.rawValue)
                                            
                                            ref.child("users").child(uid).child("memberships").child(userID).child("dateInvited").setValue(ServerValue.timestamp())
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            })
        }
    }
    
    func acceptInvite(userEmail: String, ref: DatabaseReference) {
        if let userID = Auth.auth().currentUser?.uid {
            ref.child("users").queryOrdered(byChild: "userEmail").queryEqual(toValue: userEmail).observeSingleEvent(of: .childAdded, with: { snapshot in
                if snapshot.value != nil {
                    if let userDictionary = snapshot.value as? NSDictionary {
                        if let uid = userDictionary["userID"] as? String {
                        ref.child("users").child(uid).child("circleUsers").child(userID).child("relationship").setValue(CircleUser.userRelationshipToCurrentUser.myCircleMember.rawValue)
                            ref.child("users").child(uid).child("circleUsers").child(userID).child("dateJoinedCircle").setValue(ServerValue.timestamp())
                            
                            ref.child("users").child(uid).child("circleUsers").child(userID).child("agreedInPrayerCount").setValue(0)
                            ref.child("users").child(userID).child("memberships").child(uid).child("membershipStatus").setValue(MembershipUser.currentUserMembershipStatus.member.rawValue)
                            ref.child("users").child(userID).child("memberships").child(uid).child("dateJoinedCircle").setValue(ServerValue.timestamp())
                        }
                    }
                }
            })
        }
    }
    
    func declineInvite(userEmail: String, ref: DatabaseReference) {
        if let userID = Auth.auth().currentUser?.uid {
            ref.child("users").queryOrdered(byChild: "userEmail").queryEqual(toValue: userEmail).observeSingleEvent(of: .childAdded, with: { snapshot in
                if snapshot.value != nil {
                    if let userDictionary = snapshot.value as? NSDictionary {
                        if let uid = userDictionary["userID"] as? String {
                            ref.child("users").child(userID).child("memberships").child(uid).removeValue { error, _ in
                                if let error = error {
                                    print("error 1")
                                    print("error \(error.localizedDescription)")
                                }
                            }
                            ref.child("users").child(uid).child("circleUsers").child(userID).removeValue { error, _ in
                                if let error = error {
                                    print("error 2")
                                    print("error \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
            })
        }
    }
    
    func getMembershipUserCircleUsersProfileImage(membershipUser: MembershipUser) {
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
                                                        if let circleUserIDCheck = userDictionary["userUID"] as? String {
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
    
    func downloadAdditionalMembershipUserDataFromFirebase(membershipUser: MembershipUser) {
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
                                 self.getMembershipUserCircleUsersProfileImage(membershipUser: membershipUser)
                            }
                        }
                    }
                }).resume()
            }
        }
    }
    
    func deleteCircleUserFromCurrentUserFirebase(userEmail: String, ref: DatabaseReference) {
        for circleUser in CurrentUser.firebaseCircleMembers {
            if let savedEmail = circleUser.userEmail {
                if savedEmail == userEmail {
                    if let circleUserID = circleUser.userID {
                        if let userID = Auth.auth().currentUser?.uid {
                            ref.child("users").child(userID).child("circleUsers").child(circleUserID).removeValue { error, _ in
                                if let error = error {
                                    print("error \(error.localizedDescription)")
                                }
                                self.deleteCircleUser(userEmail: userEmail, ref: ref)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func deleteCircleUser(userEmail: String, ref: DatabaseReference) {
        if let userID = Auth.auth().currentUser?.uid {
            ref.child("users").queryOrdered(byChild: "userEmail").queryEqual(toValue: userEmail).observeSingleEvent(of: .childAdded, with: { snapshot in
                if snapshot.value != nil {
                    if let userDictionary = snapshot.value as? NSDictionary {
                        if let uid = userDictionary["userID"] as? String {
                            ref.child("users").child(userID).child("circleMembers").child(uid).removeValue { error, _ in
                                if let error = error {
                                    print("error \(error.localizedDescription)")
                                }
                            }
                            ref.child("users").child(uid).child("memberships").child(userID).removeValue { error, _ in
                                if let error = error {
                                    print("error \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
            })
        }
    }
    
    func daysSinceTimeStampLabel(cellLabel: UILabel, prayer: CurrentUserPrayer, cell: PrayerTableViewCell) -> UILabel {
        if let prayerID = prayer.prayerID {
            if Auth.auth().currentUser != nil {
                if let userID = Auth.auth().currentUser?.uid {
                    Database.database().reference().child("users").child(userID).child("prayers").child(prayerID).observe(.value) { (snapshot) in
                        if let userDictionary = snapshot.value as? NSDictionary {
                            if let timeStampAsDouble = userDictionary["lastPrayedDate"] as? Double {
                                let lastPrayedString = Utilities().dayDifference(timeStampAsDouble: timeStampAsDouble)
                                cellLabel.text = "Last prayed \(lastPrayedString)"
                                PrayerTableViewCell().updateCellToShowIfRecentlyPrayed(cell: cell, lastPrayedString: lastPrayedString)
                            }
                        }
                    }
                }
            }
        }
        return cellLabel
    }
    
    func dateAnsweredLabel(cellLabel: UILabel, prayer: CurrentUserPrayer) -> UILabel {
        if let prayerID = prayer.prayerID {
            if Auth.auth().currentUser != nil {
                if let userID = Auth.auth().currentUser?.uid {
                    Database.database().reference().child("users").child(userID).child("prayers").child(prayerID).observe(.value) { (snapshot) in
                        if let userDictionary = snapshot.value as? NSDictionary {
                            if let timeStampAsDouble = userDictionary["lastPrayedDate"] as? Double {
                                let dayAnsweredString = Utilities().dateFromDouble(timeStampAsDouble: timeStampAsDouble)
                                cellLabel.text = "Answered on \(dayAnsweredString)"
                            }
                        }
                    }
                }
            }
        }
        return cellLabel
    }
    
    func saveNewCirclePrayerToFirebase(prayer: CirclePrayer, ref: DatabaseReference) {
        if let userID = Auth.auth().currentUser?.uid {
            let prayerID = NSUUID().uuidString
                postCirclePrayer(userID: userID, prayerID: prayerID, prayer: prayer, ref: ref)
        }
    }
    
    func postCirclePrayer(userID: String, prayerID: String, prayer: CirclePrayer, ref: DatabaseReference) {
        if let prayerText = prayer.prayerText {
            ref.child("users").child(userID).child("circlePrayers").child(prayerID).child("prayerText").setValue(prayerText)
        }
        if let firstName = CurrentUser.currentUser.firstName {
            ref.child("users").child(userID).child("circlePrayers").child(prayerID).child("firstName").setValue(firstName)
        }
        if let lastName = CurrentUser.currentUser.lastName {
            ref.child("users").child(userID).child("circlePrayers").child(prayerID).child("lastName").setValue(lastName)
        }
        ref.child("users").child(userID).child("circlePrayers").child(prayerID).child("lastPrayedDate").setValue(ServerValue.timestamp())
        ref.child("users").child(userID).child("circlePrayers").child(prayerID).child("howAnswered").setValue("")
        ref.child("users").child(userID).child("circlePrayers").child(prayerID).child("isAnswered").setValue(false)
        ref.child("users").child(userID).child("circlePrayers").child(prayerID).child("agreedCount").setValue(0)
        ref.child("users").child(userID).child("circlePrayers").child(prayerID).child("prayerID").setValue(prayerID)
        ref.child("users").child(userID).child("circlePrayers").child(prayerID).child("prayerOwnerUserID").setValue(userID)
    }
    
    func saveNewPrayerToFirebase(prayerText: String, prayerCategory: String, prayerID: String, ref: DatabaseReference) {
        if let userID = Auth.auth().currentUser?.uid {
            ref.child("users").child(userID).child("prayers").child(prayerID).child("prayerText").setValue(prayerText)
            ref.child("users").child(userID).child("prayers").child(prayerID).child("prayerCategory").setValue(prayerCategory)
            ref.child("users").child(userID).child("prayers").child(prayerID).child("lastPrayedDate").setValue(ServerValue.timestamp())
            ref.child("users").child(userID).child("prayers").child(prayerID).child("howAnswered").setValue("")
            ref.child("users").child(userID).child("prayers").child(prayerID).child("isAnswered").setValue(false)
            ref.child("users").child(userID).child("prayers").child(prayerID).child("prayerCount").setValue(1)
            ref.child("users").child(userID).child("prayers").child(prayerID).child("prayerID").setValue(prayerID)
        }
    }
    
    func deletePrayerFromFirebase(prayerID: String, ref: DatabaseReference) {
        if let userID = Auth.auth().currentUser?.uid {
            ref.child("users").child(userID).child("prayers").child(prayerID).removeValue { error, _ in
                if let error = error {
                    print("error \(error.localizedDescription)")
                }
            }
        }
    }
    
    func deleteCirclePrayerFromFirebase(prayerID: String, ref: DatabaseReference) {
        if let userID = Auth.auth().currentUser?.uid {
            ref.child("users").child(userID).child("circlePrayers").child(prayerID).removeValue { error, _ in
                if let error = error {
                    print("error \(error.localizedDescription)")
                }
            }
        }
    }
    
    func markPrayedInFirebase(prayerID: String, newPrayerCount: Int, ref: DatabaseReference) {
        if let userID = Auth.auth().currentUser?.uid {
            ref.child("users").child(userID).child("prayers").child(prayerID).child("lastPrayedDate").setValue(ServerValue.timestamp())
            ref.child("users").child(userID).child("prayers").child(prayerID).child("prayerCount").setValue(newPrayerCount)
        }
    }
    
    func markCirlePrayerPrayedInFirebase(prayer: CirclePrayer, newAgreedCount: Int, ref: DatabaseReference) {
        if let userID = Auth.auth().currentUser?.uid {
            if let prayerOwnerID = prayer.prayerOwnerUserID {
                if let prayerID = prayer.prayerID {
                    ref.child("users").child(prayerOwnerID).child("circlePrayers").child(prayerID).child("lastPrayedDate").setValue(ServerValue.timestamp())
                    ref.child("users").child(prayerOwnerID).child("circlePrayers").child(prayerID).child("agreedCount").setValue(newAgreedCount)
                    
                    if prayerOwnerID != userID {
                        ref.child("users").child(prayerOwnerID).child("circlePrayers").child(prayerID).child("whoAgreed").child(userID).setValue(userID)
                        ref.child("users").child(prayerOwnerID).child("circleUsers").child(userID).child("lastAgreedInPrayerDate").setValue(ServerValue.timestamp())
                        var parentIndex = 0
                        for user in CurrentUser.firebaseMembershipUsers {
                            if let membershipUserID = user.userID {
                                if membershipUserID == prayerOwnerID {
                                    if let memberCircleUsers = user.membershipUserCircleUsers {
                                        print("memberCircleUsers.count: \(memberCircleUsers.count)")
                                        var circleUserIndex = 0
                                        for membershipCircleUser in memberCircleUsers {
                                            if let membershipCircleUserID = membershipCircleUser.userID {
                                                print("1")
                                                if membershipCircleUserID == userID {
                                                    print("2")
                                                    if let agreedCount = membershipCircleUser.agreedInPrayerCount {
                                                        print("3")
                                                        let newCount = agreedCount + 1
                                                        ref.child("users").child(prayerOwnerID).child("circleUsers").child(userID).child("agreedInPrayerCount").setValue(newCount)
                                                        
                                                        var updatedCircleUserArray = memberCircleUsers
                                                        let updatedUser = membershipCircleUser
                                                        updatedUser.agreedInPrayerCount = newCount
                                                        updatedCircleUserArray[circleUserIndex] = updatedUser
                                                        
                                                        var updatedMembershipUserArray = CurrentUser.firebaseMembershipUsers
                                                        updatedMembershipUserArray[parentIndex].membershipUserCircleUsers = updatedCircleUserArray
                                                        CurrentUser.firebaseMembershipUsers = updatedMembershipUserArray
                                                    }
                                                }
                                            }
                                            circleUserIndex += 1
                                        }
                                    }
                                }
                            }
                            parentIndex += 1
                        }
                    }
                }
            }
        }
    }
    
    func markAnsweredInFirebase(prayerID: String, howAnswered: String, isAnswered: Bool, ref: DatabaseReference) {
        if let userID = Auth.auth().currentUser?.uid {
            ref.child("users").child(userID).child("prayers").child(prayerID).child("howAnswered").setValue(howAnswered)
            ref.child("users").child(userID).child("prayers").child(prayerID).child("isAnswered").setValue(true)
        }
    }
    
    func prayerFromDictionary(userDictionary: NSDictionary) -> CurrentUserPrayer {
        let prayer = CurrentUserPrayer()
        if let prayerTextCheck = userDictionary["prayerText"] as? String {
            prayer.prayerText = prayerTextCheck
        }
        if let prayerCountCheck = userDictionary["prayerCount"] as? Int {
            prayer.prayerCount = prayerCountCheck
        }
        if let prayerCategoryCheck = userDictionary["prayerCategory"] as? String {
            prayer.prayerCategory = prayerCategoryCheck
        }
        if let isAnsweredCheck = userDictionary["isAnswered"] as? Bool {
            prayer.isAnswered = isAnsweredCheck
        }
        if let prayerIDCheck = userDictionary["prayerID"] as? String {
            prayer.prayerID = prayerIDCheck
        }
        if let lastPrayedCheck = userDictionary["lastPrayed"] as? Double {
            prayer.lastPrayed = lastPrayedCheck
        }
        if let howAnsweredCheck = userDictionary["howAnswered"] as? String {
            prayer.howAnswered = howAnsweredCheck
        }
        return prayer
    }
    
    func membershipUserFromDictionary(userDictionary: NSDictionary) -> MembershipUser {
        let user = MembershipUser()
        if let membershipStatus = userDictionary["membershipStatus"] as? String {
            user.membershipStatus = membershipStatus
        }
        if let firstName = userDictionary["firstName"] as? String {
            user.firstName = firstName
        }
        if let lastName = userDictionary["lastName"] as? String {
            user.lastName = lastName
        }
        if let userID = userDictionary["userID"] as? String {
            user.userID = userID
        }
        if let userEmail = userDictionary["userEmail"] as? String {
            user.userEmail = userEmail
        }
        if let profileImageUrlString = userDictionary["profileImageURL"] as? String {
            user.profileImageAsString = profileImageUrlString
        }
        if let dateInvitedDouble = userDictionary["dateInvited"] as? Double {
            user.dateInvited = dateInvitedDouble
        }
        if let circleUsers = userDictionary["circleUsers"] as? NSDictionary {
            print("circleUsers: \(circleUsers)")
        }
        return user
    }
    
    func addNewConnectionToCurrentUserMemberships(userDictionary: NSDictionary) {
        let user = self.membershipUserFromDictionary(userDictionary: userDictionary)
        self.downloadAdditionalMembershipUserDataFromFirebase(membershipUser: user)
    }
    
    func circlePrayerFromUserDictionary(userDictionary: NSDictionary, whoAgreedDict: NSDictionary) -> CirclePrayer {
        let prayer = CirclePrayer()
        if let firstNameCheck = userDictionary["firstName"] as? String {
            prayer.firstName = firstNameCheck
        }
        if let lastNameCheck = userDictionary["lastName"] as? String {
            prayer.lastName = lastNameCheck
        }
        if let prayerTextCheck = userDictionary["prayerText"] as? String {
            prayer.prayerText = prayerTextCheck
        }
        if let prayerIDCheck = userDictionary["prayerID"] as? String {
            prayer.prayerID = prayerIDCheck
        }
        if let lastPrayedCheck = userDictionary["lastPrayedDate"] as? Double {
            prayer.lastPrayed = lastPrayedCheck
        }
        if let prayerCountCheck = userDictionary["agreedCount"] as? Int {
            prayer.agreedCount = prayerCountCheck
        }
        if let isAnsweredCheck = userDictionary["isAnswered"] as? Bool {
            prayer.isAnswered = isAnsweredCheck
        }
        if let howAnsweredCheck = userDictionary["howAnswered"] as? String {
            prayer.howAnswered = howAnsweredCheck
        }
        if let prayerOwnerUserIDCheck = userDictionary["prayerOwnerUserID"] as? String {
            prayer.prayerOwnerUserID = prayerOwnerUserIDCheck
        }
        
        prayer.whoAgreed = whoAgreedDict.allKeys as? [String]
        
        return prayer
    }
    
    func createPrayerCategories(prayers: [CurrentUserPrayer]) {
        var categories = [String]()
        for prayer in prayers {
            if let category = prayer.prayerCategory {
                if !categories.contains(category) {
                    categories.append(category)
                }
            }
        }
    }
}

