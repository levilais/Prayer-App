//
//  MembershipUser.swift
//  Prayer App
//
//  Created by Levi on 12/19/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class MembershipUser: CircleUser {
    var membershipUserCircleRef: DatabaseReference?
    var membershipUserCirclePrayersRef: DatabaseReference?
    var currentUserMembershipRef: DatabaseReference?
    
    var membershipStatus: String?
    var membershipUserCircleIds: [String]?
    var membershipUserCircleUsers: [CircleUser]?
    var membershipUserPrayers: [MembershipPrayer]?
    
    enum currentUserMembershipStatus: String {
        case invited = "invited"
        case member = "member"
        case declined = "declined"
    }
    
    func membershipUserFromSnapshot(snapshot: DataSnapshot) -> MembershipUser {
        let membershipUser = MembershipUser()
        
        membershipUser.key = snapshot.key
        membershipUser.userRef = snapshot.ref
        
        if let userDictionary = snapshot.value as? NSDictionary {
            if let membershipStatus = userDictionary["membershipStatus"] as? String {
                membershipUser.membershipStatus = membershipStatus
            }
            if let firstName = userDictionary["firstName"] as? String {
                membershipUser.firstName = firstName
            }
            if let lastName = userDictionary["lastName"] as? String {
                membershipUser.lastName = lastName
            }
            if let userID = userDictionary["userID"] as? String {
                membershipUser.userID = userID
            }
            if let userEmail = userDictionary["userEmail"] as? String {
                membershipUser.userEmail = userEmail
            }
            if let profileImageUrlString = userDictionary["profileImageURL"] as? String {
                membershipUser.profileImageAsString = profileImageUrlString
            }
            if let dateInvitedDouble = userDictionary["dateInvited"] as? Double {
                membershipUser.dateInvited = dateInvitedDouble
            }
            if let lastAgreedInPrayerDate = userDictionary["lastAgreedInPrayerDate"] as? Double {
                membershipUser.lastAgreedInPrayerDate = lastAgreedInPrayerDate
            }
        }
        
        if let circleUsersDict = snapshot.childSnapshot(forPath: "circleUsers").value as? NSDictionary {
            membershipUser.membershipUserCircleIds = circleUsersDict.allKeys as? [String]
        }
        
        if let membershipKey = membershipUser.key {
            if let currentUserKey = CurrentUser.currentUser.key {
                membershipUser.currentUserMembershipRef = Database.database().reference().child("users").child(membershipKey).child("circleUsers").child(currentUserKey)
                membershipUser.membershipUserCirclePrayersRef = Database.database().reference().child("users").child(membershipKey).child("circlePrayers")
                membershipUser.membershipUserCircleRef = Database.database().reference().child("users").child(currentUserKey).child("memberships").child(membershipKey)
                membershipUser.messagingTokensRef = Database.database().reference().child("users").child(membershipKey).child("messagingTokens")
            }
        }
        
        setMembershipUserProfileImage(membershipUser: membershipUser)
        setMessagingTokens(circleUser: membershipUser)
        
        return membershipUser
    }
    
    func setMessagingTokens(membershipUser: MembershipUser) {
        if let messagingTokensRef = membershipUser.messagingTokensRef {
            messagingTokensRef.observeSingleEvent(of: .value) { (snapshot) in
                if let tokensDict = snapshot.value as? NSDictionary {
                    if let tokens = Array(tokensDict.allKeys) as? [String] {
                        membershipUser.messagingTokens = tokens
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
            }
        }
    }
    
    func setMembershipUserProfileImage(membershipUser: MembershipUser) {
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
                                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "membershipUserDidSet"), object: nil, userInfo: nil)
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
    
    func leaveUsersCircle(membershipUser: MembershipUser) {
        if let membershipRef = membershipUser.currentUserMembershipRef {
            if let circleRef = membershipUser.membershipUserCircleRef {
                membershipRef.removeValue()
                circleRef.removeValue()
                
                var i = 0
                for firebaseMembershipUser in CurrentUser.firebaseMembershipUsers {
                    if let membershipUserEmail = membershipUser.userEmail {
                        if let emailToCheck = firebaseMembershipUser.userEmail {
                            if membershipUserEmail == emailToCheck {
                                CurrentUser.firebaseMembershipUsers.remove(at: i)
                            }
                        }
                    }
                    i += 1
                }
                
                CurrentUser.firebaseMembershipPrayers.removeAll()
            }
        }
    }

    func declineInvite(membershipUser: MembershipUser) {
        if let membershipRef = membershipUser.currentUserMembershipRef {
            if let circleRef = membershipUser.membershipUserCircleRef {
                membershipRef.removeValue()
                circleRef.removeValue()
    
                var i = 0
                for firebaseMembershipUser in CurrentUser.firebaseMembershipUsers {
                    if let membershipUserEmail = membershipUser.userEmail {
                        if let emailToCheck = firebaseMembershipUser.userEmail {
                            if membershipUserEmail == emailToCheck {
                                CurrentUser.firebaseMembershipUsers.remove(at: i)
                            }
                        }
                    }
                    i += 1
                }
            }
        }
    }
    
    func acceptInvite(membershipUser: MembershipUser) {
        if let membershipRef = membershipUser.currentUserMembershipRef {
            if let circleRef = membershipUser.membershipUserCircleRef {
                let circleDict = ["relationship":CircleUser.userRelationshipToCurrentUser.myCircleMember.rawValue,"dateJoinedCircle":ServerValue.timestamp(),"agreedInPrayerCount":0] as AnyObject
                let memberDict = ["membershipStatus":MembershipUser.currentUserMembershipStatus.member.rawValue,"dateJoinedCircle":ServerValue.timestamp()] as AnyObject
                circleRef.updateChildValues(memberDict as! [AnyHashable : Any])
                membershipRef.updateChildValues(circleDict as! [AnyHashable : Any])
                if let messagingTokens = membershipUser.messagingTokens {
                    NotificationsHelper().sendAcceptNotification(messagingTokens: messagingTokens)
                }
            }
        }
    }
}

