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
    static var firebaseUsers = [CustomUser]()
    
    func loadFirebaseData() {
        if let userID = Auth.auth().currentUser?.uid {
            let userRef = Database.database().reference().child("users").child(userID)
            userRef.observe(.value) { (snapshot) in
                CurrentUser.currentUser = CustomUser().currentUserFromSnapshot(snapshot: snapshot)
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
                print("currentUser found")
            })
            
            userRef.child("memberships").observeSingleEvent(of: .value, with: { (snapshot) -> Void in
                var newMembershipUsers = [MembershipUser]()
                for membershipSnap in snapshot.children {
                    let newMembershipUser = MembershipUser().membershipUserFromSnapshot(snapshot: membershipSnap as! DataSnapshot)
                    newMembershipUsers.append(newMembershipUser)
                }
                CurrentUser.firebaseMembershipUsers = newMembershipUsers
            })
        }
    }
    
    func inviteUserToCircle(user: CircleUser, ref: DatabaseReference) {
        print("3")
        if let userID = Auth.auth().currentUser?.uid {
            print("4")
            if let fbUserID = user.userID {
                print("5")
                ref.child("users").queryOrdered(byChild: "userID").queryEqual(toValue: fbUserID).observeSingleEvent(of: .childAdded, with: { snapshot in
                    let circleUser = CircleUser().circleUserFromSnapshot(snapshot: snapshot)
                    let circleUserDict = ["firstName":circleUser.firstName!,"lastName":circleUser.lastName!,"userEmail":circleUser.userEmail!,"userID":circleUser.key!,"profileImageURL":circleUser.profileImageAsString!,"relationship":CircleUser.userRelationshipToCurrentUser.invited.rawValue,"dateInvited":ServerValue.timestamp()] as AnyObject
                    
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
                    if let userDictionary = snapshot.value as? NSDictionary {
                        if let messagingTokens = userDictionary["messagingTokens"] as? NSDictionary {
                            if let tokens = Array(messagingTokens.allKeys) as? [String] {
                                NotificationsHelper().sendInviteNotification(messagingTokens: tokens)
                            }
                        }
                    }
                })
            }
        }
    }
    
//    func inviteUserToCircle(userEmail: String, ref: DatabaseReference) {
//        if let userID = Auth.auth().currentUser?.uid {
//            ref.child("users").queryOrdered(byChild: "userEmail").queryEqual(toValue: userEmail).observeSingleEvent(of: .childAdded, with: { snapshot in
//                let circleUser = CircleUser().circleUserFromSnapshot(snapshot: snapshot)
//                let circleUserDict = ["firstName":circleUser.firstName!,"lastName":circleUser.lastName!,"userEmail":circleUser.userEmail!,"uid":circleUser.key!,"profileImageURL":circleUser.profileImageAsString!,"relationship":CircleUser.userRelationshipToCurrentUser.invited.rawValue,"dateInvited":ServerValue.timestamp()] as AnyObject
//
//                let membershipDict = ["firstName":CurrentUser.currentUser.firstName!,"lastName":CurrentUser.currentUser.lastName!,"userID":userID,"profileImageURL":CurrentUser.currentUser.profileImageAsString!,"userEmail":CurrentUser.currentUser.userEmail!,"membershipStatus":MembershipUser.currentUserMembershipStatus.invited.rawValue,"dateInvited":ServerValue.timestamp()] as AnyObject
//
//
//                let circleRef = ref.child("users").child(userID).child("circleUsers").child(circleUser.key!)
//                let memberRef = ref.child("users").child(circleUser.key!).child("memberships").child(userID)
//
//                circleRef.setValue(circleUserDict)
//                memberRef.setValue(membershipDict)
//
//                circleUser.currentUserCircleRef = circleRef
//                circleUser.circleUserMembershipRef = memberRef
//                circleUser.relationshipToCurrentUser = CircleUser.userRelationshipToCurrentUser.invited.rawValue
//                CurrentUser.firebaseCircleMembers.append(circleUser)
//                self.setCircleUserProfileImageFromFirebase(circleUser: circleUser)
//                if let userDictionary = snapshot.value as? NSDictionary {
//                    if let messagingTokens = userDictionary["messagingTokens"] as? NSDictionary {
//                        if let tokens = Array(messagingTokens.allKeys) as? [String] {
//                            NotificationsHelper().sendInviteNotification(messagingTokens: tokens)
//                        }
//                    }
//                }
//            })
//        }
//    }
    
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
                                            print("circleUser profile image was set")
                                            CurrentUser.firebaseCircleMembers[i] = circleUser
                                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "circleUserProfileImageDidSet"), object: nil, userInfo: nil)
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
            prayerItemRef.observeSingleEvent(of: .value, with: { (snapshot) in
                let prayer = CurrentUserPrayer().currentUserPrayerFromSnapshot(snapshot: snapshot)
                if let timeStampAsDouble = prayer.lastPrayed {
                    let lastPrayedString = Utilities().dayDifference(timeStampAsDouble: timeStampAsDouble)
                    cellLabel.text = "Last prayed \(lastPrayedString)"
                    if lastPrayedString == "today" {
                        cell.prayedLastLabel.textColor = UIColor.StyleFile.TealColor
                        cell.prayedLastLabel.font = UIFont.StyleFile.LastPrayedBold
                        cell.recentlyPrayed = true
                    } else {
                        cell.prayedLastLabel.textColor = UIColor.StyleFile.MediumGrayColor
                        cell.prayedLastLabel.font = UIFont.StyleFile.LastPrayedMedium
                        cell.recentlyPrayed = false
                    }
                }
            })
        }
        return cellLabel
    }
    
    func dateAnsweredLabel(cellLabel: UILabel, prayer: CurrentUserPrayer) -> UILabel {
        if let itemRef = prayer.itemRef {
            itemRef.observeSingleEvent(of: .value, with: { (snapshot) in
                let prayer = CurrentUserPrayer().currentUserPrayerFromSnapshot(snapshot: snapshot)
                if let timeStampAsDouble = prayer.lastPrayed {
                    let dayAnsweredString = Utilities().dateFromDouble(timeStampAsDouble: timeStampAsDouble)
                    cellLabel.text = "Answered on \(dayAnsweredString)"
                }
            })
        }
        return cellLabel
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

