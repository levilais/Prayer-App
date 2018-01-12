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
    
    // POSSIBLY MOVE TO MAIN SCREEN
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
            
//            userRef.child("memberships").observe(.childAdded) { (snapshot) in
//                let membershipUser = MembershipUser().membershipUserFromSnapshot(snapshot: snapshot)
//                // do the other chain of actions here
//            }
//
//            userRef.child("memberships").observe(.childChanged) { (snapshot) in
//                let membershipUser = MembershipUser().membershipUserFromSnapshot(snapshot: snapshot)
//                var i = 0
//                for user in CurrentUser.firebaseMembershipUsers {
//                    if let userID = user.userID {
//                        if let membershipUserID = membershipUser.userID {
//                            if userID == membershipUserID {
//                                CurrentUser.firebaseMembershipUsers[i] = membershipUser
//                            }
//                        }
//                    }
//                    i += 1
//                }
//            }
//
//            userRef.child("memberships").observe(.childRemoved) { (snapshot) in
//                let membershipUser = MembershipUser().membershipUserFromSnapshot(snapshot: snapshot)
//                var i = 0
//                for user in CurrentUser.firebaseMembershipUsers {
//                    if let userID = user.userID {
//                        if let membershipUserID = membershipUser.userID {
//                            if userID == membershipUserID {
//                                CurrentUser.firebaseMembershipUsers.remove(at: i)
//                            }
//                        }
//                    }
//                    i += 1
//                }
//                // reload data here if not repsonding automatically to change in static var
//            }
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

