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
                        print("finished actual data retreival without completion handler")
                    }
                }
            }
        }
        print("emails inside function without completion: \(FirebaseHelper.firebaseUserEmails)")
    }
    
    func getUserEmails(completion: @escaping (Bool) -> Void) {
        Database.database().reference().child("users").queryOrderedByKey().observeSingleEvent(of: .value) { (snapshot) in
            if let userDictionary = snapshot.value as? NSDictionary {
                if let email = userDictionary["email"] as? String {
                    if !FirebaseHelper.firebaseUserEmails.contains(email) {
                        FirebaseHelper.firebaseUserEmails.append(email)
                        print("finished actual data retreival with completion handler")
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
                            if let profileImageUrl = userDictionary["profileImageURL"] as? String {
                                if let firstName = userDictionary["firstName"] as? String {
                                    if let lastName = userDictionary["lastName"] as? String {
                                        if let userEmail = userDictionary["userEmail"] as? String {
                                            let circleUser = CircleUser()
                                            circleUser.firstName = firstName
                                            circleUser.lastName = lastName
                                            circleUser.firebaseCircleUid = uid
                                            circleUser.userEmail = userEmail
                                            circleUser.profileImageDownloadUrlAsString = profileImageUrl
                                            CurrentUser.firebaseCircleMembers.append(circleUser)
                                            
                                            if let url = URL(string: profileImageUrl) {
                                                print("1")
                                                URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                                                    if error != nil {
                                                        print(error!.localizedDescription)
                                                        return
                                                    }
                                                    print("2")
                                                    if let imageData = data {
                                                        print("3")
                                                        if let image = UIImage(data: imageData) {
                                                            print("4")
                                                            circleUser.profileImageAsUIImage = image
                                                            var i = 0
                                                            for user in CurrentUser.firebaseCircleMembers {
                                                                print("5 - user: \(i)")
                                                                if let email = user.userEmail {
                                                                    print("6")
                                                                    if email == userEmail {
                                                                        print("7")
                                                                        CurrentUser.firebaseCircleMembers[i] = circleUser
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
                                }
                            }
                        }
                    }
                } else {
                    print ("no circle users found")
                }
            })
        }
        setCircleUsersProfileImage()
    }
    
    func setCircleUsersProfileImage() {
        print("1")
        if Auth.auth().currentUser != nil {
             print("2")
            var i = 0
            for circleUser in CurrentUser.firebaseCircleMembers {
                 print("3")
                if let circleUserID = circleUser.firebaseCircleUid {
                     print("4")
                    Database.database().reference().child("users").child(circleUserID).observe(.value) { (snapshot) in
                         print("5")
                        if let userDictionary = snapshot.value as? NSDictionary {
                             print("6")
                            if let imageURLString = userDictionary["profileImageURL"] as? String {
                                 print("7")
                                if let url = URL(string: imageURLString) {
                                     print("8")
                                    URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                                        if error != nil {
                                            print(error!.localizedDescription)
                                            return
                                        }
                                         print("9")
                                        if let imageData = data {
                                             print("10")
                                            if let image = UIImage(data: imageData) {
                                                 print("11")
                                                circleUser.profileImageAsUIImage = image
                                                CurrentUser.firebaseCircleMembers[i] = circleUser
                                            }
                                        }
                                    }).resume()
                                }
                            }
                        }
                    }
                }
                i += 1
            }
        }
    }
    
    func saveNewCircleUserToFirebase(userEmail: String, ref: DatabaseReference) {
        if let userID = Auth.auth().currentUser?.uid {
            ref.child("users").queryOrdered(byChild: "email").queryEqual(toValue: userEmail).observeSingleEvent(of: .childAdded, with: { snapshot in
                if snapshot.value != nil {
                    if let userDictionary = snapshot.value as? NSDictionary {
                        if let uid = userDictionary["userID"] as? String {
                            if let profileImageUrl = userDictionary["profileImageURL"] as? String {
                                if let firstName = userDictionary["firstName"] as? String {
                                    if let lastName = userDictionary["lastName"] as? String {
                                        ref.child("users").child(userID).child("circleUsers").child(uid).child("firstName").setValue(firstName)
                                        ref.child("users").child(userID).child("circleUsers").child(uid).child("lastName").setValue(lastName)
                                        ref.child("users").child(userID).child("circleUsers").child(uid).child("userEmail").setValue(userEmail)
                                        ref.child("users").child(userID).child("circleUsers").child(uid).child("userUID").setValue(uid)
                                        ref.child("users").child(userID).child("circleUsers").child(uid).child("profileImageURL").setValue(profileImageUrl)
                                    ref.child("users").child(userID).child("circleUsers").child(uid).child("relationship").setValue(CircleUser.userRelationshipToCurrentUser.invited.rawValue)
                                        
                                        let circleUser = CircleUser()
                                        circleUser.firstName = firstName
                                        circleUser.lastName = lastName
                                        circleUser.firebaseCircleUid = uid
                                        circleUser.userEmail = userEmail
                                        circleUser.profileImageDownloadUrlAsString = profileImageUrl
                                        CurrentUser.firebaseCircleMembers.append(circleUser)
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
    
    func deleteCircleUserFromCurrentUserFirebase(userEmail: String, ref: DatabaseReference) {
        for circleUser in CurrentUser.firebaseCircleMembers {
            if let savedEmail = circleUser.userEmail {
                if savedEmail == userEmail {
                    if let circleUserID = circleUser.firebaseCircleUid {
                        if let userID = Auth.auth().currentUser?.uid {
                            ref.child("users").child(userID).child("circleUsers").child(circleUserID).removeValue { error, _ in
                                if let error = error {
                                    print("error \(error.localizedDescription)")
                                }
                                
                                var i = 0
                                for circleUser in CurrentUser.firebaseCircleMembers {
                                    if let circleUserEmail = circleUser.userEmail {
                                        if circleUserEmail == savedEmail {
                                            print("index trying to remove from firebaseCircleMembers: \(i)")
                                            CurrentUser.firebaseCircleMembers.remove(at: i)
                                        }
                                    }
                                    i += 1
                                }
                            }
                        }
                    }
                }
            }
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

