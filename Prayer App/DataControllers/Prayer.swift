//
//  Prayer.swift
//  Prayer App
//
//  Created by Levi on 12/21/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class Prayer {
    var key : String?
    var itemRef : DatabaseReference?
    
    var prayerText : String?
    var prayerID : String?
    var prayerCount : Int?
    var lastPrayed : Double?
    var isAnswered : Bool?
    var howAnswered : String?
    
}

class CurrentUserPrayer: Prayer {
    var prayerCategory : String?
    
    func currentUserPrayerFromSnapshot(snapshot: DataSnapshot) -> CurrentUserPrayer {
        let prayer = CurrentUserPrayer()
        
        prayer.key = snapshot.key
        prayer.itemRef = snapshot.ref
        
        if let userDictionary = snapshot.value as? NSDictionary {
            
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
            if let lastPrayedCheck = userDictionary["lastPrayedDate"] as? Double {
                prayer.lastPrayed = lastPrayedCheck
            }
            if let howAnsweredCheck = userDictionary["howAnswered"] as? String {
                prayer.howAnswered = howAnsweredCheck
            }
        }
        return prayer
    }
    
    func saveNewPrayer(prayerText: String, prayerCategory: String, userRef: DatabaseReference) {
        let prayer = ["prayerText":prayerText,"prayerCategory":prayerCategory,"lastPrayedDate":ServerValue.timestamp(),"howAnswered":"","isAnswered":false,"prayerCount":1] as AnyObject
            userRef.child("prayers").childByAutoId().setValue(prayer)
    }
    
    func markPrayerAnswered(prayer: CurrentUserPrayer, howAnswered: String) {
        if let itemRef = prayer.itemRef {
            itemRef.child("howAnswered").setValue(howAnswered)
            itemRef.child("isAnswered").setValue(true)
        }
    }
    
    func markPrayerPrayed(prayer: CurrentUserPrayer) {
        if let itemRef = prayer.itemRef {
            if let prayerCount = prayer.prayerCount {
                let newPrayerCount = prayerCount + 1
                itemRef.child("lastPrayedDate").setValue(ServerValue.timestamp())
                itemRef.child("prayerCount").setValue(newPrayerCount)
            }
        }
    }
}

class CirclePrayer: Prayer {
    var prayerOwnerUserID: String?
    var agreedCount: Int?
    var firstName: String?
    var lastName: String?
    
    func circlePrayerFromSnapshot(snapshot: DataSnapshot) -> CirclePrayer {
        let prayer = CirclePrayer()
        
        prayer.key = snapshot.key
        prayer.itemRef = snapshot.ref
        
        if let userDictionary = snapshot.value as? NSDictionary {
            if let firstNameCheck = userDictionary["firstName"] as? String {
                prayer.firstName = firstNameCheck
            }
            if let lastNameCheck = userDictionary["lastName"] as? String {
                prayer.lastName = lastNameCheck
            }
            if let prayerTextCheck = userDictionary["prayerText"] as? String {
                prayer.prayerText = prayerTextCheck
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
        }
        
        return prayer
    }
    
    func saveNewCirclePrayer(prayerText: String, userRef: DatabaseReference) {
        if let userID = Auth.auth().currentUser?.uid {
            if let firstName = CurrentUser.currentUser.firstName {
                if let lastName = CurrentUser.currentUser.lastName {
                    let prayer = ["firstName":firstName,"lastName":lastName,"prayerText":prayerText,"lastPrayedDate":ServerValue.timestamp(),"howAnswered":"","isAnswered":false,"agreedCount":1,"prayerOwnerUserID":userID] as AnyObject
                    userRef.child("circlePrayers").childByAutoId().setValue(prayer)
                }
            }
        }
    }
}

class MembershipPrayer: CirclePrayer {
    var ownerCircleIds: [String]?
    var ownerCircleUsers: [CircleUser]?
    var whoAgreedIds: [String]?
    
    func membershipPrayerFromSnapshot(snapshot: DataSnapshot) -> MembershipPrayer {
        let prayer = MembershipPrayer()
        
        prayer.key = snapshot.key
        prayer.itemRef = snapshot.ref
        
        if let userDictionary = snapshot.value as? NSDictionary {
            if let firstNameCheck = userDictionary["firstName"] as? String {
                prayer.firstName = firstNameCheck
            }
            if let lastNameCheck = userDictionary["lastName"] as? String {
                prayer.lastName = lastNameCheck
            }
            if let prayerTextCheck = userDictionary["prayerText"] as? String {
                prayer.prayerText = prayerTextCheck
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
        }
        
        if let ownerID = prayer.prayerOwnerUserID {
            var circleUsers = [CircleUser]()
            let userRef = Database.database().reference().child("users").child(ownerID).child("circleUsers")
            userRef.observeSingleEvent(of: .value, with: { (snapshot) in
                for childSnap in snapshot.children {
                    let circleUser = CircleUser().circleUserFromSnapshot(snapshot: childSnap as! DataSnapshot)
                    circleUsers.append(circleUser)
                }
                prayer.ownerCircleUsers = circleUsers
            })
        }
        
        if let whoAgreedDict = snapshot.childSnapshot(forPath: "whoAgreed").value as? NSDictionary {
            if let whoAgreed = whoAgreedDict.allKeys as? [String] {
                prayer.whoAgreedIds = whoAgreed
            }
        }
        
        self.setMembershipPrayerCircleImages(membershipPrayer: prayer)
        
        return prayer
    }
    
    func setMembershipPrayerCircleImages(membershipPrayer: MembershipPrayer) {
        if let circleUsers = membershipPrayer.ownerCircleUsers {
            for circleUser in circleUsers {
                if let ref = circleUser.userRef {
                    ref.child("profileImageURL").observeSingleEvent(of: .value, with: { (snapshot) in
                        if let profileImageURL = snapshot.value as? String {
                            if let url = URL(string: profileImageURL) {
                                URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                                    if error != nil {
                                        print(error!.localizedDescription)
                                        return
                                    }
                                    if let imageData = data {
                                        if let image = UIImage(data: imageData) {
                                            circleUser.profileImageAsImage = image
                                            var arrayToAppend = [CircleUser]()
                                            if let circleUserKey = circleUser.key {
                                                var index = 0
                                                for user in circleUsers {
                                                    if let userKey = user.key {
                                                        if circleUserKey == userKey {
                                                            arrayToAppend.append(circleUser)
                                                        } else {
                                                            arrayToAppend.append(user)
                                                        }
                                                    }
                                                    index += 1
                                                }
                                                if let membershipPrayerKey = membershipPrayer.key {
                                                    var i = 0
                                                    for firebaseMembershipPrayer in CurrentUser.firebaseMembershipPrayers {
                                                        if let prayerKey = firebaseMembershipPrayer.key {
                                                            if membershipPrayerKey == prayerKey {
                                                                CurrentUser.firebaseMembershipPrayers[i] = membershipPrayer
                                                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "membershipPrayerDidSet"), object: nil, userInfo: nil)
                                                            }
                                                        }
                                                        i += 1
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }).resume()
                            }
                        }
                    })
                }
            }
            
        }
    }
}


