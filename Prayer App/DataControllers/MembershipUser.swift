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
    enum currentUserMembershipStatus: String {
        case invited = "invited"
        case member = "member"
        case declined = "declined"
    }
}
