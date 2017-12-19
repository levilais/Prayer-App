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
                if let email = userDictionary["email"] as? String {
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
                if let email = userDictionary["email"] as? String {
                    if !FirebaseHelper.firebaseUserEmails.contains(email) {
                        FirebaseHelper.firebaseUserEmails.append(email)
                    }
                }
            }
            completion(true)
        }
    }
    
    func loadCircleMembers() {
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
        }
    }
    
    func inviteUserToCircle(userEmail: String, ref: DatabaseReference) {
        if let userID = Auth.auth().currentUser?.uid {
            ref.child("users").queryOrdered(byChild: "email").queryEqual(toValue: userEmail).observeSingleEvent(of: .childAdded, with: { snapshot in
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
            ref.child("users").queryOrdered(byChild: "email").queryEqual(toValue: userEmail).observeSingleEvent(of: .childAdded, with: { snapshot in
                if snapshot.value != nil {
                    if let userDictionary = snapshot.value as? NSDictionary {
                        if let uid = userDictionary["userID"] as? String {
//                            if let currentUserFirstName = CurrentUser.firstName {
//                                print("6")
//                                if let currentUserLastName = CurrentUser.lastName {
//                                    print("7")
//                                    ref.child("users").child(uid).child("memberships").child(userID).child("firstName").setValue(currentUserFirstName)
//                                    ref.child("users").child(uid).child("memberships").child(userID).child("lastName").setValue(currentUserLastName)
                                    ref.child("users").child(uid).child("memberships").child(userID).child("userID").setValue(userID)
                                    
//                                }
//                            }
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
            ref.child("users").queryOrdered(byChild: "email").queryEqual(toValue: userEmail).observeSingleEvent(of: .childAdded, with: { snapshot in
                if snapshot.value != nil {
                    if let userDictionary = snapshot.value as? NSDictionary {
                        if let uid = userDictionary["userID"] as? String {
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
                                let dayAnsweredString = Utilities().dayAnswered(timeStampAsDouble: timeStampAsDouble)
                                cellLabel.text = dayAnsweredString
                            }
                        }
                    }
                }
            }
        }
        return cellLabel
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
    
    func markPrayedInFirebase(prayerID: String, newPrayerCount: Int, ref: DatabaseReference) {
        if let userID = Auth.auth().currentUser?.uid {
            ref.child("users").child(userID).child("prayers").child(prayerID).child("lastPrayedDate").setValue(ServerValue.timestamp())
            ref.child("users").child(userID).child("prayers").child(prayerID).child("prayerCount").setValue(newPrayerCount)
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

