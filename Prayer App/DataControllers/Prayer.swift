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
        }
        
        if let whoAgreedDict = snapshot.childSnapshot(forPath: "whoAgreed").value as? NSDictionary {
            prayer.whoAgreed = whoAgreedDict.allKeys as? [String]
        }
        
        return prayer
    }
}

