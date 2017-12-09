//
//  CurrentUser.swift
//  Prayer App
//
//  Created by Levi on 11/25/17.
//  Copyright © 2017 App Volks. All rights reserved.
//


import Foundation
import UIKit

class CurrentUser {
    static var isLoggedIn: Bool?
    static var hasAllowedContactAccess = false
    static var circleMembers = [CircleUser]()
    
    static var profileImage: UIImage?
    static var firstName: String?
    static var lastName: String?
    static var currentUserUID: String?
}
