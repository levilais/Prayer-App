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
            let userRef = Database.database().reference().child("users").child(userID)
            userRef.observe(.value) { (snapshot) in
                CurrentUser.currentUser = User().currentUserFromSnapshot(snapshot: snapshot)
            }
            
            userRef.child("circleUsers").observe(.value, with: { snapshot in
                for snapChild in snapshot.children {
                    let circleUser = CircleUser().circleUserFromSnapshot(snapshot: snapChild as! DataSnapshot)
                    if let circleUserEmail = circleUser.userEmail {
                        var userExists = false
                        if CurrentUser.firebaseCircleMembers.count > 0 {
                            var matchDetermined = false
                            while matchDetermined == false {
                                for userToCheck in CurrentUser.firebaseCircleMembers {
                                    if let userToCheckEmail = userToCheck.userEmail {
                                        if userToCheckEmail == circleUserEmail {
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
                    }
                    self.setCircleUserProfileImageFromFirebase(circleUser: circleUser)
                }
            })

//                userRef.observe(.value) { (snapshot) in
//                if let userDictionary = snapshot.value as? NSDictionary {
//                    let user = User()
//
//                    if let firstName = userDictionary["firstName"] as? String {
//                        user.firstName = firstName
//                    }
//                    if let lastName = userDictionary["lastName"] as? String {
//                        user.lastName = lastName
//                    }
//                    if let userEmail = userDictionary["userEmail"] as? String {
//                        user.userEmail = userEmail
//                    }
//                    if let profileImageAsUrlString = userDictionary["profileImageURL"] as? String {
//                        user.profileImageAsString = profileImageAsUrlString
//                    }
//                    user.userID = userID
                
//                    CurrentUser.currentUser = user
//                }
//            }
            
            userRef.child("memberships").observe(.childAdded) { (snapshot) in
                if let userDictionary = snapshot.value as? NSDictionary {
                    FirebaseHelper().addNewConnectionToCurrentUserMemberships(userDictionary: userDictionary)
                }
            }

            userRef.child("memberships").observe(.childChanged) { (snapshot) in
                if let userDictionary = snapshot.value as? NSDictionary {
                    let snapshotMembershipUser = FirebaseHelper().membershipUserFromDictionary(userDictionary: userDictionary)
                    var i = 0
                    for user in CurrentUser.firebaseMembershipUsers {
                        if let userID = user.userID {
                            if let snapshotUserID = snapshotMembershipUser.userID {
                                if userID == snapshotUserID {
                                    CurrentUser.firebaseMembershipUsers[i] = snapshotMembershipUser
                                }
                            }
                        }
                        i += 1
                    }
                }
                // reload data here if not repsonding automatically to change in static var
            }

            userRef.child("memberships").observe(.childRemoved) { (snapshot) in
                if let userDictionary = snapshot.value as? NSDictionary {
                    let snapshotMembershipUser = FirebaseHelper().membershipUserFromDictionary(userDictionary: userDictionary)
                    var i = 0
                    for user in CurrentUser.firebaseMembershipUsers {
                        if let userID = user.userID {
                            if let snapshotUserID = snapshotMembershipUser.userID {
                                if userID == snapshotUserID {
                                    CurrentUser.firebaseMembershipUsers.remove(at: i)
                                }
                            }
                        }
                        i += 1
                    }
                    // reload data here if not repsonding automatically to change in static var
                }
            }
        }
    }
    
    func inviteUserToCircle(userEmail: String, ref: DatabaseReference) {
        if let userID = Auth.auth().currentUser?.uid {
            ref.child("users").queryOrdered(byChild: "userEmail").queryEqual(toValue: userEmail).observeSingleEvent(of: .childAdded, with: { snapshot in
                let circleUser = CircleUser().circleUserFromSnapshot(snapshot: snapshot)
                let circleUserDict = ["firstName":circleUser.firstName!,"lastName":circleUser.lastName!,"userEmail":circleUser.userEmail!,"uid":circleUser.key!,"profileImageURL":circleUser.profileImageAsString!,"relationship":CircleUser.userRelationshipToCurrentUser.invited.rawValue,"dateInvited":ServerValue.timestamp()] as AnyObject
                let membershipDict = ["firstName":CurrentUser.currentUser.firstName!,"lastName":CurrentUser.currentUser.lastName!,"userID":userID,"profileImageURL":CurrentUser.currentUser.profileImageAsString!,"userEmail":CurrentUser.currentUser.userEmail!,"membershipStatus":MembershipUser.currentUserMembershipStatus.invited.rawValue,"dateInvited":ServerValue.timestamp()] as AnyObject
                                                        
                                                        
                let circleRef = ref.child("users").child(userID).child("circleUsers").child(circleUser.key!)
                let memberRef = ref.child("users").child(circleUser.key!).child("memberships").child(userID)
                
                circleRef.setValue(circleUserDict)
                memberRef.setValue(membershipDict)
                
                circleUser.currentUserCircleRef = circleRef
                circleUser.circleUserMembershipRef = memberRef
                circleUser.relationshipToCurrentUser = CircleUser.userRelationshipToCurrentUser.invited.rawValue
                CurrentUser.firebaseCircleMembers.append(circleUser)
                self.setCircleUserProfileImageFromFirebase(circleUser: circleUser)
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
    
    func setMembershipUserProfileImageFromFirebase(membershipUser: MembershipUser) {
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
    
//    func deleteCircleUserFromCurrentUserFirebase(userEmail: String, ref: DatabaseReference) {
//        for circleUser in CurrentUser.firebaseCircleMembers {
//            if let savedEmail = circleUser.userEmail {
//                if savedEmail == userEmail {
//                    if let circleUserID = circleUser.userID {
//                        if let userID = Auth.auth().currentUser?.uid {
//                            ref.child("users").child(userID).child("circleUsers").child(circleUserID).removeValue { error, _ in
//                                if let error = error {
//                                    print("error \(error.localizedDescription)")
//                                }
//                                self.deleteCircleUser(userEmail: userEmail, ref: ref)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    func deleteCircleUser(userEmail: String, ref: DatabaseReference) {
//        if let userID = Auth.auth().currentUser?.uid {
//            ref.child("users").queryOrdered(byChild: "userEmail").queryEqual(toValue: userEmail).observeSingleEvent(of: .childAdded, with: { snapshot in
//                if snapshot.value != nil {
//                    if let userDictionary = snapshot.value as? NSDictionary {
//                        if let uid = userDictionary["userID"] as? String {
//                            ref.child("users").child(userID).child("circleUsers").child(uid).removeValue { error, _ in
//                                if let error = error {
//                                    print("error \(error.localizedDescription)")
//                                }
//                            }
//                            ref.child("users").child(uid).child("memberships").child(userID).removeValue { error, _ in
//                                if let error = error {
//                                    print("error \(error.localizedDescription)")
//                                }
//                            }
//                        }
//                    }
//                }
//            })
//        }
//    }
    
    func daysSinceTimeStampLabel(cellLabel: UILabel, prayer: CurrentUserPrayer, cell: PrayerTableViewCell) -> UILabel {
        if let prayerItemRef = prayer.itemRef {
            prayerItemRef.observe(.value) { (snapshot) in
                let prayer = CurrentUserPrayer().currentUserPrayerFromSnapshot(snapshot: snapshot)
                if let timeStampAsDouble = prayer.lastPrayed {
                    let lastPrayedString = Utilities().dayDifference(timeStampAsDouble: timeStampAsDouble)
                    cellLabel.text = "Last prayed \(lastPrayedString)"
                    PrayerTableViewCell().updateCellToShowIfRecentlyPrayed(cell: cell, lastPrayedString: lastPrayedString)
                }
            }
        }
        return cellLabel
    }
    
    func dateAnsweredLabel(cellLabel: UILabel, prayer: CurrentUserPrayer) -> UILabel {
        if let itemRef = prayer.itemRef {
            itemRef.observe(.value) { (snapshot) in
                let prayer = CurrentUserPrayer().currentUserPrayerFromSnapshot(snapshot: snapshot)
                if let timeStampAsDouble = prayer.lastPrayed {
                    let dayAnsweredString = Utilities().dateFromDouble(timeStampAsDouble: timeStampAsDouble)
                    cellLabel.text = "Answered on \(dayAnsweredString)"
                }
            }
        }
        return cellLabel
    }
    
    func markCirlePrayerPrayedInFirebase(prayer: CirclePrayer, newAgreedCount: Int) {
        let ref = Database.database().reference()
        if let userID = Auth.auth().currentUser?.uid {
            if let prayerOwnerID = prayer.prayerOwnerUserID {
                let ownerRef = ref.child("users").child(prayerOwnerID)
                if let prayerID = prayer.key {
                    ownerRef.child("circlePrayers").child(prayerID).child("lastPrayedDate").setValue(ServerValue.timestamp())
                    ownerRef.child("circlePrayers").child(prayerID).child("agreedCount").setValue(newAgreedCount)
                    
                    if prayerOwnerID != userID {
                        ownerRef.child("circlePrayers").child(prayerID).child("whoAgreed").child(userID).setValue(userID)
                        ownerRef.child("circleUsers").child(userID).child("lastAgreedInPrayerDate").setValue(ServerValue.timestamp())
                        var parentIndex = 0
                        for user in CurrentUser.firebaseMembershipUsers {
                            if let membershipUserID = user.userID {
                                if membershipUserID == prayerOwnerID {
                                    if let memberCircleUsers = user.membershipUserCircleUsers {
                                        print("memberCircleUsers.count: \(memberCircleUsers.count)")
                                        var circleUserIndex = 0
                                        for membershipCircleUser in memberCircleUsers {
                                            if let membershipCircleUserID = membershipCircleUser.userID {
                                                if membershipCircleUserID == userID {
                                                    if let agreedCount = membershipCircleUser.agreedInPrayerCount {
                                                        let newCount = agreedCount + 1
                                                        ownerRef.child("circleUsers").child(userID).child("agreedInPrayerCount").setValue(newCount)
                                                        
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
        FirebaseHelper().setMembershipUserProfileImageFromFirebase(membershipUser: user)
        return user
    }
    
    func addNewConnectionToCurrentUserMemberships(userDictionary: NSDictionary) {
        let user = self.membershipUserFromDictionary(userDictionary: userDictionary)
        self.downloadAdditionalMembershipUserDataFromFirebase(membershipUser: user)
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

