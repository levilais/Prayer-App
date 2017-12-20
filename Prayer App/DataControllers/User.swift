//
//  User.swift
//  Prayer App
//
//  Created by Levi on 12/17/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation

import Foundation
import Firebase
import Contacts
import ContactsUI

class User {
    var dateJoined: Double?
    var firstName: String?
    var lastName: String?
    var userID: String?
    var userEmail: String?
    var profileImageAsString: String? // will be converted to url then image
    var profileImageAsData: Data?
    var profileImageAsImage: UIImage?
    
    func getFullName(user: User) -> String {
        var fullName = ""
        if let first = user.firstName {
            if let last = user.lastName {
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

