//
//  CircleUsers.swift
//  Prayer App
//
//  Created by Levi on 11/25/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation
import UIKit

class CircleUser {
    var firstName: String?
    var lastName: String?
    var dateAdded: Date?
    var lastAgreedInPrayerDate: Date?
    var agreedInPrayerCount: Int?
    var profileImage: Data?
    var circleUserID: Float32?
    var circleMemberEmail: String?
    var circleMemberPhoneNumber: String?

    func getFullName() -> String {
        var fullName = ""
        if let first = firstName {
            if let last = lastName {
                fullName += first
                if fullName != "" {
                    fullName += " " + last
                } else {
                    fullName += last
                }
            }
        }
        return fullName
    }
}

