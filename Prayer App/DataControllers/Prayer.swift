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
    var whoAgreed: [String]?
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
        
        if let whoAgreedDict = snapshot.childSnapshot(forPath: "whoAgreed").value as? NSDictionary {
            prayer.whoAgreed = whoAgreedDict.allKeys as? [String]
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

